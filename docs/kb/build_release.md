# Build & Release Workflow

This document tracks the workflow for building and releasing the Outcall application to Google Play.

## 1. Automated Release Workflow (Recommended)
The primary release mechanism is the `release.sh` script, which categorizes versions, tags the repository, and triggers the GitHub Actions CI/CD pipeline.

### Step 1: Execute the Release Script
```bash
# Usage: ./scripts/release.sh <version> <build_number> [release_notes]
./scripts/release.sh 1.8.3 37 "Major update with new animal calls and calibration."
```
1. Updates `pubspec.yaml` versions.
2. Updates `distribution/whatsnew/en-US.txt`.
3. Commits and tags the release (e.g., `v1.8.3`).
4. Pushes to `main`, triggering `.github/workflows/deploy_release.yml`.

### Step 2: GitHub Actions Pipeline
The pipeline triggers on any tag starting with `v`.
1. **quality-gate**: Restores `google-services.json`, runs `flutter analyze` and `flutter test`.
2. **deploy**: Restores Keystore, builds the Release AAB (`flutter build appbundle --release --obfuscate --split-debug-info`), uploads to Play Store Alpha Track, and creates a GitHub Release.

## 2. Manual Build & Upload Tools
If automation fails, use these specialized scripts:

### Local Production Build
```bash
flutter build appbundle --release --obfuscate --split-debug-info=build/app/outputs/symbols
```

### Manual Play Store Upload
**Service Account Method (Recommended)**: `scripts/upload_to_play_store.py`
- Utilizes `scripts/play-store-key.json`.
- Usage: `python scripts/upload_to_play_store.py --track alpha --name "v1.8.3" --notes "Fixes" --aab <path>`

**OAuth2 Interactive Method**: `scripts/upload_play.py`
- Utilizes user OAuth flow. Best for one-off manual uploads without service accounts.

### Google Drive Upload (For Testers)
Used to upload APKs directly to the "Benchmark Apps" folder.
```bash
flutter build apk --release
python scripts/upload_apk_gdrive.py
```

## 3. Troubleshooting & Common Pitfalls

- **Gradle Daemon Exit / OOM**: Increase memory limit in `android/gradle.properties`:
  ```properties
  org.gradle.jvmargs=-Xmx4G -XX:MaxMetaspaceSize=1G
  org.gradle.workers.max=1
  ```
- **Missing `google-services.json`**: Ensure the file is present in `android/app/`.
- **Stale Build Locks**:
  ```bash
  cd android && ./gradlew --stop
  rm -f .gradle/noVersion/buildLogic.lock
  ```
