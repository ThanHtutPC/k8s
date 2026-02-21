#!/bin/bash

# ==============================
# ISO to QCOW2 VM Creator Script
# ==============================

# Check arguments
if [ $# -lt 2 ]; then
    echo "Usage: $0 <path-to-iso> <disk-size-in-GB>"
    echo "Example: $0 ubuntu-24.04-live-server.iso 20"
    exit 1
fi

ISO_PATH=$1
DISK_SIZE=$2
DISK_NAME="vm-disk.qcow2"

echo "Creating QCOW2 disk..."

# Create qcow2 disk
qemu-img create -f qcow2 $DISK_NAME ${DISK_SIZE}G

echo "Starting QEMU VM..."

# Start VM
qemu-system-x86_64 \
    -enable-kvm \
    -m 2048 \
    -cdrom $ISO_PATH \
    -drive file=$DISK_NAME,format=qcow2 \
    -boot d

echo "VM stopped."
