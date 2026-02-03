#!/bin/bash
echo "Fixing complete LLVM toolchain for Dart..."

TARGET_DIR="/usr/lib/llvm-20/bin"

if [ ! -d "$TARGET_DIR" ]; then
    echo "Directory $TARGET_DIR does not exist. Please check your llvm installation."
    exit 1
fi

# Function to safely create symlink
link_tool() {
    local tool_name=$1
    local target_name=$2
    
    # Try to find the tool in system path
    local tool_path=$(which $tool_name)
    
    if [ -z "$tool_path" ]; then
        echo "Warning: tool '$tool_name' not found in PATH."
        # Fallback: check if it exists in target dir with version suffix?
        # For now, just skip.
        return
    fi

    echo "Linking $tool_name from $tool_path to $TARGET_DIR/$target_name"
    sudo ln -sf "$tool_path" "$TARGET_DIR/$target_name"
}

# Ensure lld is installed (just in case)
sudo apt-get install -y lld llvm

# Fix lld
link_tool "lld" "ld.lld"
link_tool "lld" "ld"

# Fix ar (archiver)
link_tool "llvm-ar-20" "llvm-ar"
# If llvm-ar-20 not found, try generic llvm-ar
if [ -z "$(which llvm-ar-20)" ]; then
    link_tool "llvm-ar" "llvm-ar"
fi
link_tool "llvm-ar" "ar"

# Fix nm (symbol list)
link_tool "llvm-nm-20" "llvm-nm"
# If llvm-nm-20 not found, try generic llvm-nm
if [ -z "$(which llvm-nm-20)" ]; then
    link_tool "llvm-nm" "llvm-nm"
fi
link_tool "llvm-nm" "nm"

# Fix strip
link_tool "llvm-strip-20" "llvm-strip"
# If llvm-strip-20 not found, try generic llvm-strip
if [ -z "$(which llvm-strip-20)" ]; then
    link_tool "llvm-strip" "llvm-strip"
fi
link_tool "llvm-strip" "strip"

echo "Toolchain fix complete. Listing $TARGET_DIR:"
ls -l "$TARGET_DIR"
