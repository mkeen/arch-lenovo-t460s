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
parted /dev/${DISK} --script mkpart primary ext4 513MiB 10000MiB

# Encrypted Tmp Partition
parted /dev/${DISK} --script mkpart primary ext4 10001MiB 20000MiB

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
mount /dev/${DISK}5 /mnt
mkdir -p /mnt/boot
mount /dev/${DISK}1 /mnt/boot
mkdir -p /mnt/var
mount /dev/mapper/var /mnt/var

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
cp skel/etc/mkinitcpio.conf /mnt/etc
cp skel/etc/sudoers /mnt/etc
cp skel/etc/openswap.conf /mnt/etc

arch-chroot /mnt sh /etc/configure.sh

reboot
