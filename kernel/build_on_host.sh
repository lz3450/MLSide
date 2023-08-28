#!/bin/bash

set -e

export KBUILD_BUILD_HOST=Ubuntu
export KBUILD_BUILD_USER=mlside
export KBUILD_BUILD_TIMESTAMP="$(date -u '+%Y/%m/%d %T %z')"

if [ ! -d linux ]; then
    git clone -b linux-5.15.y https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git
fi

# prepare
cd linux
git pull
mkdir -p build
cp ../config build/.config

make O=build nconfig
cp build/.config ../config

# build
make O=build -j $(nproc) all

# install
kernelrelease=$(make O=build -s kernelrelease)
image_name=$(make O=build -s image_name)
rootfsdir="$(realpath ../ubuntu2004)"
modulesdir="$rootfsdir/usr/lib/modules/$kernelrelease"

mkdir -p "$rootfsdir"
loopdev=$(sudo losetup -fP --show ../../qemu/ubuntu2004.img)

sudo mount ${loopdev}p2 "$rootfsdir"
# Check if the mount was successful
if mountpoint -q "$rootfsdir"; then
    echo "Successfully mounted ${loopdev}p2 to $rootfsdir"
else
    echo "Failed to mount ${loopdev}p2 to $rootfsdir"
    # Detach the loop device if mount fails to clean up
    sudo losetup -d $loopdev
    exit 1
fi
sudo mount ${loopdev}p1 "$rootfsdir"/boot/efi

sudo make INSTALL_MOD_PATH="$rootfsdir/usr" INSTALL_MOD_STRIP=1 O=build modules_install
sudo install -Dm755 build/$image_name "$modulesdir"/vmlinuz-MLSide
sudo install -Dm755 build/$image_name "$rootfsdir"/boot/vmlinuz-MLSide
sudo install -Dm755 build/$image_name "$rootfsdir"/boot/efi/vmlinuz-MLSide

sudo rm "$rootfsdir"/usr/lib/modules/$kernelrelease/{build,source}
sudo ln -sf /usr/src/linux-headers-$kernelrelease "$rootfsdir"/usr/lib/modules/$kernelrelease/source
sudo ln -sf /usr/src/linux-headers-$kernelrelease/build "$rootfsdir"/usr/lib/modules/$kernelrelease/build

sudo rsync -a \
    --exclude='*.o' \
    --exclude='*.ko*' \
    --exclude='*.a' \
    --exclude='*.o.cmd' \
    --exclude='*.o.d' \
    --exclude='*.so.dbg' \
    --exclude='.tmp_vmlinux.btf' \
    --exclude='.git*' \
    --exclude='.clang-format' \
    --exclude='.cocciconfig' \
    --exclude='.get_maintainer.ignore' \
    --exclude='.mailmap' \
    --exclude='.rustfmt.toml' \
    . "$rootfsdir"/usr/src/linux-headers-$kernelrelease

sleep 1
sudo umount -R "$rootfsdir"
sleep 1
rmdir "$rootfsdir"
sleep 1
sudo losetup -d "$loopdev"
