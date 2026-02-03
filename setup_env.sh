#!/bin/bash
echo "Installing dependencies..."
sudo apt-get update
sudo apt-get install -y cmake ninja-build clang pkg-config libgtk-3-dev liblzma-dev libasound2-dev

echo "Configuring Flutter PATH..."
FLUTTER_PATH="/home/neo/.gemini/antigravity/scratch/development/flutter/bin"
if grep -q "$FLUTTER_PATH" ~/.bashrc; then
    echo "Flutter path already in .bashrc"
else
    echo "export PATH=\"\$PATH\":\"$FLUTTER_PATH\"" >> ~/.bashrc
    echo "Added Flutter to .bashrc"
fi

echo "Setup complete! Please restart your terminal or run: source ~/.bashrc"
