# Config
DISK=sda

# Prep
timedatectl set-ntp true
pacman -Syy
pacman --noconfirm -S cryptsetup

# Prepare Partitions
parted /dev/${DISK} --script mklabel gpt

# Boot Partition
parted /dev/${DISK} --script mkpart ESP fat32 1MiB 513MiB
parted /dev/${DISK} --script set 1 boot on
mkfs.fat -F32 /dev/${DISK}1

# Encrypted Swap Partition
parted /dev/${DISK} --script mkpart primary linux-swap 513MiB 10000MiB
mkswap /dev/mapper/swap
cryptsetup -v --cipher aes-xts-plain64 --key-size 256 --hash sha256 --iter-time 2000 --use-urandom --verify-passphrase --batch-mode luksFormat ${DISK}2
cryptsetup -v open /dev/sda2 swap
swapon /dev/mapper/swap

# Encrypted Tmp Partition
parted /dev/${DISK} --script mkpart primary ext4 10001MiB 20000MiB
cryptsetup open --type plain /dev/${DISK}3 tmp --key-file /dev/random
mkfs.ext4 /dev/mapper/tmp

# Encrypted Var Partition
parted /dev/${DISK} --script mkpart primary ext4 20001MiB 50000MiB
cryptsetup open --type plain /dev/${DISK}4 var
mkfs.ext4 /dev/mapper/var

# / Partition
parted /dev/${DISK} --script mkpart primary ext4 50001MiB 80000MiB
mkfs.ext4 /dev/${DISK}5

# Encrypted Home Folder (/home/mkeen) Partition
parted /dev/${DISK} --script mkpart primary ext4 80001MiB 100%
cryptsetup open --type plain /dev/${DISK}6 home
mkfs.ext4 /dev/mapper/home

# Mount All
mount /dev/${DISK}5 /mnt
mkdir -p /mnt/boot
mount /dev/${DISK}1 /mnt/boot
mkdir -p /mnt/var
mount /dev/mapper/var /mnt/var
mkdir -p /mnt/home
mount /dev/mapper/home /mnt/home
mkdir -p /mnt/tmp
mount /dev/mapper/tmp /mnt/tmp

# Prepare Mirrors
pacman --noconfirm -Sy reflector
reflector --verbose --country 'United States' -l 200 -p http --sort rate --save /etc/pacman.d/mirrorlist

# Pacstrap
pacstrap /mnt base base-devel pam_mount
genfstab -U /mnt >> /mnt/etc/fstab

# Skel files
cp skel/etc/unsecure.key /mnt/etc
cp skel/etc/crypttab /mnt/etc
cp skel/etc/security/pam_mount.conf.xml /mnt/etc/security
cp skel/etc/pam.d/gdm-password /mnt/etc/pam.d
cp skel/etc/pam.d/system-auth /mnt/etc/pam.d
cp configure.sh /mnt/etc
cp skel/etc/mkinitcpio.conf /etc/mkinitcpio.conf
cp skel/etc/sudoers /etc
# Probably needs permissions fixes inside of configure.sh's first lines

arch-chroot /mnt sh /etc/configure.sh

# Once the work in arch-chroot completes, return back to the script, and reboot
reboot
