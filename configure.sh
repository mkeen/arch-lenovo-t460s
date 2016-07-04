# Config
DISK=sda

# Locale
echo "en_US.UTF-8 UTF-8" > /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf

# Time
tzselect
ln -s /usr/share/zoneinfo/America/New_York /etc/localtime
hwclock --systohc --utc

# Configure Boot
pacman -S intel-ucode efibootmgr --noconfirm
efibootmgr -d /dev/${DISK} -p 1 -c -L "Arch Linux" -l /vmlinuz-linux -u "i915.preliminary_hw_support=1 root=/dev/${DISK}5 rw initrd=/intel-ucode.img initrd=/initramfs-linux.img"
efibootmgr

# Create User
useradd mkeen --create-home --password \$1\$o4fUysim\$.ije9dcXJAbmiU.M3OhPg1
chmod 0440 /etc/sudoers
chown root /etc/sudoers

# Set Hostname
echo "resin" > /etc/hostname

# Set Root Password
passwd

# Install Base Customizations
echo "
[archlinuxfr]
SigLevel = Never
Server = http://repo.archlinux.fr/\$arch
" >> /etc/pacman.conf
pacman -Syy --noconfirm
pacman --noconfirm -S yaourt gnome

su mkeen --command "yaourt --noconfirm -S mkinitcpio-openswap"
su mkeen --command "yaourt --noconfirm -S broadcom-wl"

mkinitcpio -p linux

systemctl enable NetworkManager
systemctl enable gdm

exit

