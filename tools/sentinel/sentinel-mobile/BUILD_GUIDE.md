
# Sentinel Mobile - APK Build Guide

This guide will help you build the **Sentinel Prime** mobile app into a functional APK that you can install on your Android device.

## Option 1: Fast Build (GitHub Actions)
The easiest way to get an APK without installing Flutter locally.

1.  **Clone/Upload** the `sentinel-mobile/` folder to a new GitHub repository.
2.  Add a **GitHub Action** workflow (`.github/workflows/build.yml`):
    ```yaml
    name: Build APK
    on: [push]
    jobs:
      build:
        runs-on: ubuntu-latest
        steps:
          - uses: actions/checkout@v3
          - uses: subosito/flutter-action@v2
            with:
              flutter-version: '3.10.0'
          - run: flutter pub get
          - run: flutter build apk --split-per-abi
          - uses: actions/upload-artifact@v3
            with:
              name: release-apk
              path: build/app/outputs/flutter-apk/app-release.apk
    ```
3.  On every push, GitHub will build the APK and provide a download link in the "Actions" tab.

## Option 2: Local Build
If you have Flutter installed on your primary machine:

1.  Navigate to the directory: `cd sentinel-mobile`
2.  Install dependencies: `flutter pub get`
3.  Build the APK: `flutter build apk`
4.  Find your APK at: `build/app/outputs/flutter-apk/app-release.apk`

## Features Included
- **Auto-Handshake**: Automatically fetches the latest tunnel URL.
- **Tunnel Bypass**: Injects your Public IP password automatically so you don't have to type it.
- **Sentinel Prime UI**: Custom high-fidelity cyberpunk aesthetic.

---
**Sentinel Core Status: GLOBAL_SYNC_ENABLED**
