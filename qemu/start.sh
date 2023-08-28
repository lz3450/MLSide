#!/usr/bin/bash

taskset -c 0-15 qemu-system-x86_64 \
    -smp 16 -m 16G -enable-kvm \
    -cpu host,+sgx,+sgxlc,+sgx-provisionkey,+sgx-debug \
    -object memory-backend-epc,id=mem1,size=65M,prealloc=on \
    -M sgx-epc.0.memdev=mem1 \
    -bios /usr/share/ovmf/OVMF.fd \
    -drive file=./ubuntu2004.img,index=0,media=disk,format=raw \
    -nic user,hostfwd=tcp::2222-:22
