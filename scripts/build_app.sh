#!/bin/bash
set -e

# Set up environment if not already set (assuming standard install paths from our setup)
export PATH="$PATH:$HOME/development/flutter/bin"
export PATH="$PATH:$HOME/Android/Sdk/cmdline-tools/latest/bin"
export PATH="$PATH:$HOME/Android/Sdk/platform-tools"

echo "=== Cleaning project ==="
flutter clean

echo "=== Getting dependencies ==="
flutter pub get

echo "=== Building Android APK ==="
flutter build apk --release

echo "=== Building Linux Bundle ==="
flutter build linux --release

echo "=== Build Complete ==="
echo "Android APK: build/app/outputs/flutter-apk/app-release.apk"
echo "Linux Bundle: build/linux/x64/release/bundle/"
