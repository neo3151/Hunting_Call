#!/bin/bash

# Build APK script
echo "Building APK..."
flutter build apk --release

if [ $? -eq 0 ]; then
    echo "APK built successfully!"
    echo "You can find it at: build/app/outputs/flutter-apk/app-release.apk"
else
    echo "Failed to build APK."
    exit 1
fi
