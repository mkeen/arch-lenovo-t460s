# Config
DISK=sda

# Prep
timedatectl set-ntp true
pacman --noconfirm -S cryptsetup pam_mount

# Prepare Partitions
parted /dev/${DISK} --script mklabel msdos
# todo, delete existing

# Boot Partition
parted /dev/${DISK} --script mkpart ESP fat32 1MiB 513MiB
parted /dev/${DISK} --script disk_set boot on
mkfs.fat -F32 /dev/${DISK}1

# Swap Partition
parted /dev/${DISK} --script mkpart primary linux-swap 513MiB 49GiB
cryptsetup open --type plain /dev/${DISK}2 container --key-file /dev/random
mkswap /dev/mapper/${DISK}2
swapon /dev/mapper/${DISK}2

# Tmp Partition
parted /dev/${DISK} --script mkpart primary ext4 49GiB 99GiB
cryptsetup open --type plain /dev/${DISK}3 container --key-file /dev/random
mkfx.ext4 /dev/mapper/${DISK}3

# Var Partition
parted /dev/${DISK} --script mkpart primary ext4 100GiB 199GiB
cryptsetup open /dev/${DISK}4
mkfs.ext4 /dev/mapper/${DISK}4

# / Partition
parted /dev/${DISK} --script mkpart primary ext4 200GiB 299GiB
mkfs.ext4 /dev/${DISK}5

# Home Folder (/home/mkeen) Partition
parted /dev/${DISK} --script mkpart primary ext4 300GiB 100%
cryptsetup open /dev/${DISK}6
mkfs.ext4 /dev/mapper/${DISK}6



# Mount All
mount /dev/${DISK}5 /mnt
mkdir -p /mnt/boot
mount /dev/${DISK}1 /mnt/boot
mkdir -p /mnt/var
mount /dev/${DISK}3 /mnt/var
mkdir -p /mnt/home
mount /dev/${DISK}6 /mnt/home

# Prepare Mirrors
pacman -Sy reflector
reflector --verbose --country 'United States' -l 200 -p http --sort rate --save /etc/pacman.d/mirrorlist

# Pacstrap
pacstrap /mnt base base-devel
genfstab -U /mnt >> /mnt/etc/fstab
arch-chroot /mnt /bin/bash

# Locale
echo "en_US.UTF-8 UTF-8" > /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf

# Time
tzselect
ln -s /usr/share/zoneinfo/America/New_York /etc/localtime
hwclock --systohc --utc

# Configure Boot
pacman -S intel-ucode --noconfirm
efibootmgr -d /dev/${DISK} -p 1 -c -L "Arch Linux" -l /vmlinuz-linux -u "i915.preliminary_hw_support=1 root=/dev/${DISK}4 rw initrd=/intel-ucode.img initrd=/initramfs-linux.img"
mkinitcpio -p linux
efibootmgr -v

# Create User
useradd mkeen --create-home --password \$1\$o4fUysim\$.ije9dcXJAbmiU.M3OhPg1
cp sudoers /etc/sudoers
chmod 0440 /etc/sudoers
chown root /etc/sudoers

# Set Hostname
echo "resin" > /etc/hostname

# Install Base Customizations
echo "
[archlinuxfr]
SigLevel = Never
Server = http://repo.archlinux.fr/\$arch
" >> /etc/pacman.conf
pacman -Syy --noconfirm
pacman -S yaourt --noconfirm

yaourt --noconfirm -S reflector gnome NetworkManager gdm pam_mount



systemctl enable gdm
exit
reboot
