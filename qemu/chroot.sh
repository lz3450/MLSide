#!/usr/bin/bash

mountpoint=ubuntu2004
loopdev=$(sudo losetup -fP --show ubuntu2004.img)

cleanup() {
    set +e

    if [ -n "${mountpoint}" ]; then
        for attempt in $(seq 10); do
            for fs in dev/pts dev sys proc run; do
                mount | grep -q "${mountpoint}/${fs}" && sudo umount -R "${mountpoint}/${fs}" 2> /dev/null
            done
            mount | grep -q "${mountpoint}" && sudo umount -R "${mountpoint}" 2> /dev/null
            if [ $? -ne 0 ]; then
                break
            fi
            sleep 1
        done
    fi

    sudo losetup -d "${loopdev}"
    if [ -d "${mountpoint}" ]; then
        rmdir "${mountpoint}"
    fi
}
trap cleanup EXIT

set -e
# set -x

mkdir -p "$mountpoint"
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
for fs in dev sys proc run; do
    sudo mount --rbind /"${fs}" "${mountpoint}"/"${fs}"
    sudo mount --make-rslave "${mountpoint}"/"${fs}"
done

sudo chroot "$mountpoint"/ /bin/zsh

for fs in dev sys proc run; do
    sudo umount -R "${mountpoint}"/$fs
done
sleep 1
sudo umount -R "$mountpoint"
sleep 1
rmdir "$mountpoint"
sleep 1
sudo losetup -d "$loopdev"
