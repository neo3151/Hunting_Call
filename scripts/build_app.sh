#!/bin/bash
set -e

# Set up environment
export PATH="$PATH:$HOME/development/flutter/bin"
export PATH="$PATH:$HOME/Android/Sdk/cmdline-tools/latest/bin"
export PATH="$PATH:$HOME/Android/Sdk/platform-tools"

echo "=== Cleaning project ==="
flutter clean

echo "=== Getting dependencies ==="
flutter pub get

echo "=== Building Android App Bundle (AAB) with Symbols ==="
# --obfuscate and --split-debug-info help with symbolicated stack traces in Crashlytics
flutter build appbundle --release \
    --obfuscate \
    --split-debug-info=build/app/outputs/symbols

echo "=== Packaging Debug Symbols ==="
# Native symbols (unstripped) from intermediates
cd build/app/intermediates/merged_native_libs/release/mergeReleaseNativeLibs/out/lib
zip -r ../../../../../../outputs/native-debug-symbols.zip .
cd - > /dev/null

# Dart symbols
cd build/app/outputs/symbols
zip -r ../dart-debug-symbols.zip .
cd - > /dev/null

echo "=== Building Android APK ==="
flutter build apk --release

echo "=== Building Linux Bundle ==="
flutter build linux --release

echo "=== Build Complete ==="
echo "Android AAB: build/app/outputs/bundle/release/app-release.aab"
echo "Native Symbols: build/app/outputs/native-debug-symbols.zip"
echo "Dart Symbols: build/app/outputs/dart-debug-symbols.zip"
echo "Linux Bundle: build/linux/x64/release/bundle/"
