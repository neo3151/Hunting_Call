#!/bin/bash
echo "Fixing libstdc++ link for Clang..."

# Find the location of libstdc++.so
LIBSTDC_PATH=$(find /usr/lib/gcc/x86_64-linux-gnu -name "libstdc++.so" | head -n 1)

if [ -z "$LIBSTDC_PATH" ]; then
    echo "Could not find libstdc++.so. Please ensure g++ is installed."
    exit 1
fi

echo "Found libstdc++ at: $LIBSTDC_PATH"

# Create a symlink in /usr/lib/x86_64-linux-gnu/ where ld searches by default
if [ ! -f /usr/lib/x86_64-linux-gnu/libstdc++.so ]; then
    echo "Creating symlink in /usr/lib/x86_64-linux-gnu/"
    sudo ln -s "$LIBSTDC_PATH" /usr/lib/x86_64-linux-gnu/libstdc++.so
    echo "Symlink created."
else
    echo "Symlink already exists at /usr/lib/x86_64-linux-gnu/libstdc++.so"
    ls -l /usr/lib/x86_64-linux-gnu/libstdc++.so
fi

echo "Done. Please try building again."
