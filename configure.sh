# Config
DISK=sda # Apple MBA

# Locale
echo "en_US.UTF-8 UTF-8" > /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf

# Time
timedatectl set-timezone America/New_York
ln -s /usr/share/zoneinfo/America/New_York /etc/localtime
hwclock --systohc --utc

# Configure Boot
pacman -S intel-ucode efibootmgr --noconfirm
efibootmgr -d /dev/${DISK} -p 1 -c -L "Arch Linux" -l /vmlinuz-linux -u "i915.preliminary_hw_support=1 root=/dev/${DISK}5 rw initrd=/intel-ucode.img initrd=/initramfs-linux.img"
efibootmgr

# Create User
useradd mkeen --no-create-home --password \$1\$o4fUysim\$.ije9dcXJAbmiU.M3OhPg1

# Fix Permissions
chmod 0440 /etc/sudoers
chown root /etc/sudoers
mkdir -p /home/mkeen
chown mkeen /home/mkeen

# Set Hostname
echo "resin" > /etc/hostname

# Set Root Password
passwd

# Install Base Customizations
pacman -S gnome --noconfirm
echo "
[archlinuxfr]
SigLevel = Never
Server = http://repo.archlinux.fr/\$arch

[DEB_Arch_Extra]
SigLevel = Optional TrustAll
Server = http://mega.nz/linux/MEGAsync/Arch_Extra/\$arch
" >> /etc/pacman.conf
pacman -Syy --noconfirm
pacman --noconfirm -S yaourt megasync

su mkeen --command "yaourt --noconfirm -S broadcom-wl" # Apple MBA

mkinitcpio -p linux

# Polish Everything
# - Cursor
yaourt --noconfirm -S xcursor-pinux
sudo mkdir -p /etc/dconf/db/gdm.d/
touch /etc/dconf/db/gdm.d/10-cursor-settings
echo "[org/gnome/desktop/interface]
cursor-theme='PArch-24'" > /etc/dconf/db/gdm.d/10-cursor-settings
dconf update

systemctl enable NetworkManager
#systemctl enable gdm

mv /root/user.sh /home/mkeen/user.sh
chmod 777 user.sh
su mkeen --command user.sh
rm -rf /home/mkeen/user.sh

exit
