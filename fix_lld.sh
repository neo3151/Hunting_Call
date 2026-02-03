#!/bin/bash
echo "Fixing LLD linker for Dart..."

echo "Installing lld..."
sudo apt-get update && sudo apt-get install -y lld

# Find where lld was installed
LLD_PATH=$(which lld)
if [ -z "$LLD_PATH" ]; then
    echo "Could not find lld after installation. Please install manually."
    exit 1
fi
echo "Found lld at: $LLD_PATH"

# Symlink it to where Dart is looking (/usr/lib/llvm-20/bin)
TARGET_DIR="/usr/lib/llvm-20/bin"
if [ -d "$TARGET_DIR" ]; then
    echo "Creating symlinks in $TARGET_DIR..."
    sudo ln -sf "$LLD_PATH" "$TARGET_DIR/ld.lld"
    sudo ln -sf "$LLD_PATH" "$TARGET_DIR/ld"
    echo "Symlinks created."
else
    echo "Target directory $TARGET_DIR does not exist. Skipping symlink."
fi

echo "Done. Please try building again."
