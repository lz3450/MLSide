#!/bin/bash

set -e

# packages
cat > /etc/apt/sources.list << EOF
deb http://us.archive.ubuntu.com/ubuntu focal main restricted universe
deb-src http://us.archive.ubuntu.com/ubuntu focal main restricted universe

deb http://security.ubuntu.com/ubuntu/ focal-security main restricted
deb-src http://security.ubuntu.com/ubuntu/ focal-security main restricted

deb http://us.archive.ubuntu.com/ubuntu/ focal-updates main restricted universe
deb-src http://us.archive.ubuntu.com/ubuntu/ focal-updates main restricted universe
EOF

apt update
apt install -y \
    curl wget \
    openssh-server \
    zsh \
    nano \
    git
apt upgrade -y

dpkg-reconfigure locales
dpkg-reconfigure tzdata

# hostname
read -p 'hostname: ' HOSTNAME
echo $HOSTNAME > /etc/hostname

# users
echo "root password:"
passwd
chsh

wget -O /root/.zshrc https://git.grml.org/f/grml-etc-core/etc/zsh/zshrc
mkdir -p /root/.zsh
git clone --depth 1 https://github.com/zsh-users/zsh-syntax-highlighting.git /root/.zsh/zsh-syntax-highlighting
git clone --depth 1 https://github.com/zsh-users/zsh-autosuggestions.git /root/.zsh/zsh-autosuggestions
echo 'source ~/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh' >> /root/.zshrc
echo 'source ~/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh' >> /root/.zshrc

useradd -m -U -G sudo -s /bin/zsh mlside
echo "mlside password:"
passwd mlside

cat > /home/mlside/oh-my-zsh.sh << EOF
sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
git clone --depth 1 https://github.com/zsh-users/zsh-syntax-highlighting.git ~/.oh-my-zsh/custom/plugins
git clone --depth 1 https://github.com/zsh-users/zsh-autosuggestions.git ~/.oh-my-zsh/custom/plugins
sed -e "/^ZSH_THEME/s/\"robbyrussell\"/random/" \
    -e "/^plugins=/s/git/archlinux git vscode python tmux zsh-autosuggestions zsh-syntax-highlighting/" \
    -i ~/.zshrc
EOF

# network
cat > /etc/systemd/network/ethernet.network << EOF
[Match]
Name=en*
Name=eth*

[Network]
DHCP=yes
EOF

systemctl enable systemd-networkd

# boot
bootctl install --esp-path=/boot/efi

mkdir -p /boot/efi/loader/entries

cat > /boot/efi/loader/loader.conf << EOF
timeout 3
console-mode max
default ubuntu.conf
EOF

cat > /boot/efi/loader/entries/ubuntu.conf << EOF
title   Ubuntu 20.04
linux   /vmlinuz
initrd  /initrd.img
options root=PARTUUID= rw
EOF

blkid >> /boot/efi/loader/entries/ubuntu.conf
nano /boot/efi/loader/entries/ubuntu.conf

apt install linux-image-generic
cp /boot/vmlinuz /boot/efi
cp /boot/initrd.img /boot/efi

# fstab
blkid >> /etc/fstab
nano /etc/fstab
