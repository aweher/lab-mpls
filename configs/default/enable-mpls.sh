#!/bin/bash

# Enable MPLS
sysctl -w net.mpls.conf.lo.input=1
for iface in $(ls /sys/class/net | grep ^eth); do
    sysctl -w net.mpls.conf.$iface.input=1
done
sysctl -w net.mpls.platform_labels=1048575