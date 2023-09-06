#!/bin/bash

for i in $(seq 0 $(nproc)); do
    current_value=$(sudo rdmsr -p"$i" -d 0x1a0)
    # printf "%x\n" $current_value
    new_value=$(( current_value | 0x4000000000 ))
    # printf "%x\n" $new_value
    sudo wrmsr -p"$i" 0x1a0 $new_value
done

#echo performance | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
#cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
#cat /proc/cpuinfo | grep MHz
