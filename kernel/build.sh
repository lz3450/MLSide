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
modulesdir="/usr/lib/modules/$kernelrelease"

sudo make INSTALL_MOD_PATH="/usr" INSTALL_MOD_STRIP=1 O=build modules_install
sudo install -Dm755 build/$image_name "$modulesdir"/vmlinuz-MLSide
sudo install -Dm755 build/$image_name /boot/vmlinuz-MLSide
sudo install -Dm755 build/$image_name /boot/efi/vmlinuz-MLSide
