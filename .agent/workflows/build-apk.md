---
description: Build an Android APK for the project
---
// turbo-all
1. Build the debug APK (arm64 only, ~227MB vs 340MB fat APK):
```powershell
flutter build apk --debug --split-per-abi --target-platform android-arm64
```

2. Upload to Google Drive (optimized):
```powershell
rclone copyto "build\app\outputs\flutter-apk\app-arm64-v8a-debug.apk" "gdrive:OUTCALL/dev-builds/app-debug.apk" --progress --drive-chunk-size 256M --no-check-dest --stats 2s
```

3. The APK will be available at:
- Local: `build/app/outputs/flutter-apk/app-arm64-v8a-debug.apk`
- Drive: `OUTCALL/dev-builds/app-debug.apk`

**Note**: For release builds, use `./scripts/build_app.sh` instead.
**Note**: For older 32-bit devices, remove `--target-platform` to build all ABIs.
