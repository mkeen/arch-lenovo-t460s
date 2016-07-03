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
cryptsetup open --type plain /dev/${DISK}2 swap --key-file /dev/random
mkswap /dev/mapper/swap
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
pacstrap /mnt base base-devel
genfstab -U /mnt >> /mnt/etc/fstab

# Skel files
cp skel/etc/unsecure.key /etc
cp skel/etc/crypttab /etc
cp skel/etc/security/pam_mount.conf.xml /etc/security
cp skel/etc/pam.d/gdm-password /etc/pam.d
cp skel/etc/pam.d/system-auth /etc/pam.d
# Probably needs permissions fixes

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
cp skel/etc/mkinitcpio.conf /etc/mkinitcpio.conf
mkinitcpio -p linux
efibootmgr -d /dev/${DISK} -p 1 -c -L "Arch Linux" -l /vmlinuz-linux -u "i915.preliminary_hw_support=1 root=/dev/${DISK}5 rw initrd=/intel-ucode.img initrd=/initramfs-linux.img"

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

yaourt --noconfirm -S pam_mount gnome emacs nvm-git git wget unzip

# Configure Erlang Version Manager
git clone https://github.com/robisonsantos/evm.git
cd evm
./install
cd ../
rm -rf evm
echo "source $HOME/.evm/scripts/evm" > ~/.bashrc
exec $SHELL
evm install OTP_18.3
evm default OTP_18.3

# Configure Elixir Version Manager
git clone git://github.com/mururu/exenv.git ~/.exenv
echo 'export PATH="$HOME/.exenv/bin:$PATH"' >> ~/.bashrc
echo 'eval "$(exenv init -)"' >> ~/.bashrc
exec $SHELL
wget https://github.com/elixir-lang/elixir/archive/v1.3.1.zip
unzip v1.3.1.zip
mv elixir-1.3.1/ ~/.exenv/versions/1.3.1
exenv global 1.3.1
exenv rehash

systemctl enable gdm
exit
reboot
