#!/usr/bin/bash

set -x

mkdir -p ubuntu2004

sudo losetup -P /dev/loop0 ubuntu2004.img
sudo mount /dev/loop0p2 ubuntu2004
sudo mount /dev/loop0p1 ubuntu2004/boot/efi

sudo mkdir -p ubuntu2004/run/systemd/resolve
sudo cp /etc/resolv.conf ubuntu2004/run/systemd/resolve/stub-resolv.conf

sudo chroot ubuntu2004/ /bin/zsh

sudo umount -R ubuntu2004
rmdir ubuntu2004

sudo losetup -d /dev/loop0
