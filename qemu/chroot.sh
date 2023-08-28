#!/usr/bin/bash

set -e
# set -x

mountpoint=ubuntu2004
mkdir -p "$mountpoint"

loopdev=$(sudo losetup -fP --show ubuntu2004.img)
sudo mount ${loopdev}p2 "$mountpoint"

# Check if the mount was successful
if mountpoint -q "$mountpoint"; then
    echo "Successfully mounted ${loopdev}p2 to $mountpoint"
else
    echo "Failed to mount ${loopdev}p2 to $mountpoint"
    # Detach the loop device if mount fails to clean up
    sudo losetup -d $loopdev
    exit 1
fi
sudo mount ${loopdev}p1 "$mountpoint"/boot/efi

# 
sudo mkdir -p "$mountpoint"/run/systemd/resolve
sudo cp /etc/resolv.conf "$mountpoint"/run/systemd/resolve/stub-resolv.conf

sudo chroot "$mountpoint"/ /bin/zsh

sleep 1
sudo umount -R "$mountpoint"
sleep 1
rmdir "$mountpoint"
sleep 1
sudo losetup -d "$loopdev"
