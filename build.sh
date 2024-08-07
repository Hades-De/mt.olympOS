#!/usr/bin/env bash

# File names
BOOT_FILE="boot.asm"
BOOT2_FILE="boot2.asm"
BOOT_BIN="boot.bin"
BOOT2_BIN="boot2.bin"
DISK_IMG="disk.img"

# Assemble the bootloader programs
echo "Assembling $BOOT_FILE..."
nasm -f bin $BOOT_FILE -o $BOOT_BIN

echo "Assembling $BOOT2_FILE..."
nasm -f bin $BOOT2_FILE -o $BOOT2_BIN

# Create an empty disk image
echo "Creating disk image..."
qemu-img create -f raw $DISK_IMG 1M

# Write the bootloader and second stage to the disk image
echo "Writing bootloader to disk image..."
dd if=$BOOT_BIN of=$DISK_IMG bs=512 count=1 conv=notrunc

echo "Writing second stage to disk image..."
dd if=$BOOT2_BIN of=$DISK_IMG bs=512 seek=1 conv=notrunc
