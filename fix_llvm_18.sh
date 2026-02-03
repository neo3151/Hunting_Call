#!/bin/bash
set -e

echo "Fixing LLVM 18 toolchain for Hunting Call..."

# 1. Install lld
echo "Installing lld..."
sudo apt-get update && sudo apt-get install -y lld

# 2. Configure symlinks
TARGET_DIR="/usr/lib/llvm-18/bin"
LLD_PATH=$(which lld)

if [ -z "$LLD_PATH" ]; then
    echo "Error: lld not found after installation."
    exit 1
fi

echo "Creating symlinks in $TARGET_DIR..."

sudo ln -sf "$LLD_PATH" "$TARGET_DIR/ld.lld"
sudo ln -sf "$LLD_PATH" "$TARGET_DIR/ld"

# Also ensure ar, nm, strip are linked if they don't exist
if [ ! -f "$TARGET_DIR/ar" ]; then
    sudo ln -sf "$TARGET_DIR/llvm-ar" "$TARGET_DIR/ar"
fi

if [ ! -f "$TARGET_DIR/nm" ]; then
    sudo ln -sf "$TARGET_DIR/llvm-nm" "$TARGET_DIR/nm"
fi

if [ ! -f "$TARGET_DIR/strip" ]; then
    sudo ln -sf "$TARGET_DIR/llvm-strip" "$TARGET_DIR/strip"
fi

echo "Toolchain fix complete. Listing $TARGET_DIR contents:"
ls -l "$TARGET_DIR/ld.lld" "$TARGET_DIR/ld" "$TARGET_DIR/ar" "$TARGET_DIR/nm" "$TARGET_DIR/strip"

echo "Done. You should now be able to run: flutter run -d Linux"
