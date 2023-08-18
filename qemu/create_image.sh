#!/bin/bash

set -e
set -u
# set -x

script_name="$(basename "${0}")"
script_path="$(readlink -f "${0}")"
script_dir="$(dirname "${script_path}")"
img="ubuntu2004.img"
mountpoint="2004"
loop=""
target=""

# Show an INFO message
# $1: message string
info() {
    local _msg="$1"
    printf '[%s] INFO: %s\n' "${script_name}" "${_msg}"
}

# Show a WARNING message
# $1: message string
warning() {
    local _msg="$1"
    printf '[%s] WARNING: %s\n' "${script_name}" "${_msg}" >&2
}

# Show an ERROR message then exit with status
# $1: message string
# $2: exit code number (with 0 does not exit)
error() {
    local _msg="$1"
    local _error="$2"
    printf '[%s] ERROR: %s\n' "${script_name}" "${_msg}" >&2
    if [ "${_error}" -gt 0 ]; then
        exit "${_error}"
    fi
}

create_img() {
    info "Creating image..."

    if [ -f "${img}" ]; then
        rm -f "${img}"
    fi

    qemu-img create "${img}" 16G

    sudo parted -s "${img}" \
        mktable gpt \
        unit s \
        mkpart fat32 2048s 1048575s \
        mkpart ext4 1048576s 100% \
        set 1 boot on \
        print
}

setup_loop() {
    info "Setup loop device..."

    loop=$(losetup -f)
    info "Loop device is \"${loop}\""

    sudo losetup -P "${loop}" "${img}"
}

format_img() {
    info "Formating image..."

    sudo mkfs.fat -F32 "${loop}p1"
    sudo mkfs.ext4 "${loop}p2"
}

mount_img() {
    info "Mounting image..."

    sudo mkdir -p "${mountpoint}"
    sudo mount "${loop}p2" "${mountpoint}"
    sudo mkdir -p "${mountpoint}"/boot/efi
    sudo mount "${loop}p1" "${mountpoint}"/boot/efi
}

bootstrap_img () {
    info "Bootstrap image..."

    # debootstrap
    sudo debootstrap focal "${mountpoint}" http://us.archive.ubuntu.com/ubuntu

    sync
}

configure_img() {
    info "Configuring image..."

    sudo cp "initialize.sh" "${mountpoint}"/root/initialize.sh

    for fs in dev sys proc run; do
        sudo mount --rbind /"${fs}" "${mountpoint}"/"${fs}"
        sudo mount --make-rslave "${mountpoint}"/"${fs}"
    done

    info "Running initialize.sh..."
    LC_ALL=C sudo chroot "${mountpoint}" /bin/bash -c "/root/initialize.sh"
    LC_ALL=C sudo chroot "${mountpoint}" sync

    for fs in dev sys proc run; do
        sudo umount -R "${mountpoint}"/$fs
    done

    sudo rm -rf "${mountpoint}"/dev/*
    sudo rm -rf "${mountpoint}"/sys/*
    sudo rm -rf "${mountpoint}"/proc/*
    sudo rm -rf "${mountpoint}"/run/*
    sudo rm -rf "${mountpoint}"/var/log/*
    sudo rm -rf "${mountpoint}"/var/lib/apt/lists/*
    sudo rm -rf "${mountpoint}"/var/cache/apt/archives/*.deb
    sudo rm -rf "${mountpoint}"/var/tmp/*
    sudo rm -rf "${mountpoint}"/tmp/*

    sync
}

cleanup() {
    info "Cleaning..."
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

    sudo losetup -d "${loop}"
    if [ -d "${mountpoint}" ]; then
        rmdir "${mountpoint}"
    fi
}
trap cleanup EXIT

################################################################################

start_time=$(date +%s)

echo "****************************************************************"
echo "                Create Raspberry Pi image                "
echo "****************************************************************"

create_img
setup_loop
format_img
mount_img
bootstrap_img
configure_img

end_time=$(date +%s)
total_time=$((end_time-start_time))

echo "****************************************************************"
echo "                Execution time Information                "
echo "****************************************************************"
echo "${script_name} : End time - $(date)"
echo "${script_name} : Total time - $(date -d@${total_time} -u +%H:%M:%S)"
