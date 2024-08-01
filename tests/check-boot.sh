#!/usr/bin/env bash

# File to check
FILE_TO_CHECK="result/bin/mt.olympOS.img"

# Check if file is bootable
if file "$FILE_TO_CHECK" | grep -q "DOS/MBR boot sector"; then
  echo "File is bootable"
  exit 0
else
  echo "File is not bootable"
  exit 1
fi
