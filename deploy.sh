#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# OUTCALL — Play Store Deploy Script
# Usage:
#   ./deploy.sh              → bump patch, build AAB, upload to production
#   ./deploy.sh --internal   → same but uploads to internal test track
#   ./deploy.sh --build-only → bump + build, skip upload (manual upload)
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail

TRACK="production"
BUILD_ONLY=false

for arg in "$@"; do
  case $arg in
    --internal)   TRACK="internal" ;;
    --build-only) BUILD_ONLY=true ;;
  esac
done

PUBSPEC="pubspec.yaml"
PLAY_KEY="${PLAY_STORE_JSON_KEY:-android/fastlane/play-store-key.json}"

# ── 1. Verify play store key exists (unless build-only) ───────────────────────
if [ "$BUILD_ONLY" = false ] && [ ! -f "$PLAY_KEY" ]; then
  echo ""
  echo "  ✗ Play Store service account key not found at: $PLAY_KEY"
  echo "    See DEPLOY_SETUP.md for instructions."
  echo ""
  exit 1
fi

# ── 2. Bump versionCode and patch versionName in pubspec.yaml ─────────────────
CURRENT_VERSION=$(grep '^version:' "$PUBSPEC" | sed 's/version: //')
VERSION_NAME=$(echo "$CURRENT_VERSION" | cut -d'+' -f1)
VERSION_CODE=$(echo "$CURRENT_VERSION" | cut -d'+' -f2)

NEW_CODE=$((VERSION_CODE + 1))

# Bump patch digit of versionName (e.g. 3.1.0 → 3.1.1)
MAJOR=$(echo "$VERSION_NAME" | cut -d'.' -f1)
MINOR=$(echo "$VERSION_NAME" | cut -d'.' -f2)
PATCH=$(echo "$VERSION_NAME" | cut -d'.' -f3)
NEW_PATCH=$((PATCH + 1))
NEW_NAME="$MAJOR.$MINOR.$NEW_PATCH"

NEW_VERSION="$NEW_NAME+$NEW_CODE"

sed -i "s/^version: .*/version: $NEW_VERSION/" "$PUBSPEC"
echo "  ✓ Version bumped: $CURRENT_VERSION → $NEW_VERSION"

# ── 3. Build release AAB ──────────────────────────────────────────────────────
echo "  ↻ Building release AAB..."
flutter build appbundle --release
echo "  ✓ AAB built: build/app/outputs/bundle/release/app-release.aab"

AAB_PATH="build/app/outputs/bundle/release/app-release.aab"

if [ "$BUILD_ONLY" = true ]; then
  echo ""
  echo "  ✓ Build-only mode — skipping upload."
  echo "    Upload manually: $AAB_PATH"
  echo ""
  exit 0
fi

# ── 4. Upload via fastlane ────────────────────────────────────────────────────
echo "  ↻ Uploading to Play Console ($TRACK track)..."
cd android
PLAY_STORE_JSON_KEY="../$PLAY_KEY" fastlane $([[ "$TRACK" == "internal" ]] && echo "deploy_internal" || echo "deploy")
cd ..

echo ""
echo "  ✓ Done! v$NEW_VERSION uploaded to Play Store ($TRACK track)."
echo ""
