#!/usr/bin/env bash
# ──────────────────────────────────────────────────────────────────────────────
# release.sh — Bump version, commit, tag, and push to trigger CI/CD deploy.
#
# Usage:
#   ./scripts/release.sh 1.8.3 37         # Sets version 1.8.3+37
#   ./scripts/release.sh 1.8.3 37 "Fixed update screen"  # With custom notes
# ──────────────────────────────────────────────────────────────────────────────
set -euo pipefail

VERSION="${1:?Usage: release.sh <version> <build_number> [release_notes]}"
BUILD="${2:?Usage: release.sh <version> <build_number> [release_notes]}"
NOTES="${3:-Bug fixes and improvements.}"
TAG="v${VERSION}"
FULL_VERSION="${VERSION}+${BUILD}"

echo "🏷️  Preparing release: ${TAG} (${FULL_VERSION})"

# 1. Update pubspec.yaml
sed -i "s/^version: .*/version: ${FULL_VERSION}/" pubspec.yaml
echo "   ✅ pubspec.yaml → version: ${FULL_VERSION}"

# 2. Update whatsnew for Play Store
echo "${NOTES}" > distribution/whatsnew/en-US.txt
echo "   ✅ Release notes updated"

# 3. Commit
git add pubspec.yaml distribution/whatsnew/en-US.txt
git commit -m "release: ${TAG} — ${NOTES}"
echo "   ✅ Committed"

# 4. Tag
git tag -a "${TAG}" -m "${NOTES}"
echo "   ✅ Tagged ${TAG}"

# 5. Push
git push origin main --tags
echo ""
echo "🚀 Pushed! GitHub Actions will now:"
echo "   1. Run analyze + tests"
echo "   2. Build release AAB"
echo "   3. Upload to Play Store (alpha)"
echo "   4. Create GitHub Release"
echo ""
echo "   Monitor: https://github.com/neo3151/Hunting_Call/actions"
