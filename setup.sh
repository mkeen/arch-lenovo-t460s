# Config
DISK=sda # Apple MBA

# Prep
timedatectl set-ntp true
pacman -Syy
pacman --noconfirm -S cryptsetup
head -c 256 /dev/urandom > initialkey

# Prepare Partitions
parted /dev/${DISK} --script mklabel gpt

# Boot Partition
parted /dev/${DISK} --script mkpart ESP fat32 1MiB 513MiB
parted /dev/${DISK} --script set 1 boot on
mkfs.fat -F32 /dev/${DISK}1

# Encrypted Swap Partition
parted /dev/${DISK} --script mkpart primary ext4 513MiB 10000MiB
cryptsetup -v --key-size 256 -c aes-cbc-plain64 -i 2000 -h sha256 --key-file initialkey -l 256 --batch-mode luksFormat /dev/${DISK}2
cryptsetup -v --key-size 256 -c aes-cbc-plain64 -i 2000 -h sha256 --key-file initialkey -l 256 --batch-mode open /dev/${DISK}2 swap
mkswap /dev/mapper/swap

# Encrypted Tmp Partition
parted /dev/${DISK} --script mkpart primary ext4 10001MiB 20000MiB
cryptsetup -v --key-size 256 -c aes-cbc-plain64 -i 2000 -h sha256 --key-file initialkey -l 256 --batch-mode luksFormat /dev/${DISK}3
cryptsetup -v --key-size 256 -c aes-cbc-plain64 -i 2000 -h sha256 --key-file initialkey -l 256 --batch-mode open /dev/${DISK}3 tmp
mkfs.ext2 /dev/mapper/tmp

# Encrypted Var Partition
parted /dev/${DISK} --script mkpart primary ext4 20001MiB 50000MiB
cryptsetup -v --verify-passphrase --batch-mode luksFormat /dev/${DISK}4
cryptsetup -v open /dev/${DISK}4 var
mkfs.ext4 /dev/mapper/var

# / Partition
parted /dev/${DISK} --script mkpart primary ext4 50001MiB 80000MiB
mkfs.ext4 /dev/${DISK}5

# Encrypted Home Folder (mkeen) Partition
parted /dev/${DISK} --script mkpart primary ext4 80001MiB 100%
cryptsetup -v --verify-passphrase --batch-mode luksFormat /dev/${DISK}6
cryptsetup -v open /dev/${DISK}6 mkeen
mkfs.ext4 /dev/mapper/mkeen

# Mount All
swapon /dev/mapper/swap
mount /dev/${DISK}5 /mnt
mkdir -p /mnt/boot
mount /dev/${DISK}1 /mnt/boot
mkdir -p /mnt/var
mount /dev/mapper/var /mnt/var
mkdir -p /mnt/tmp
mount /dev/mapper/tmp /mnt/tmp

# Prepare Mirrors
pacman --noconfirm -Sy reflector
reflector --verbose --country 'United States' -l 200 -p http --sort rate --save /etc/pacman.d/mirrorlist

# Pacstrap
pacstrap /mnt base base-devel pam_mount
genfstab /mnt >> /mnt/etc/fstab

# Skel files
cp skel/etc/crypttab /mnt/etc
cp skel/etc/security/pam_mount.conf.xml /mnt/etc/security
cp skel/etc/pam.d/login /mnt/etc/pam.d
cp skel/etc/pam.d/gdm-password /mnt/etc/pam.d
cp skel/etc/pam.d/system-auth /mnt/etc/pam.d
cp configure.sh /mnt/etc
cp skel/etc/mkinitcpio.conf /mnt/etc
cp skel/etc/sudoers /mnt/etc
cp skel/etc/modprobe.d/hid_apple.conf /mnt/etc/modprobe.d # Apple MBA, tilde support

# Temporary user configuration executable
cp skel/home/mkeen/user.sh /mnt/root

arch-chroot /mnt sh /etc/configure.sh

reboot
