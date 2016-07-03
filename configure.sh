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
mkinitcpio -p linux
efibootmgr -d /dev/${DISK} -p 1 -c -L "Arch Linux" -l /vmlinuz-linux -u "i915.preliminary_hw_support=1 root=/dev/${DISK}5 rw initrd=/intel-ucode.img initrd=/initramfs-linux.img"

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
