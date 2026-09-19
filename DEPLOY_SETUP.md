# Play Store Deploy Setup

One-time setup to enable `./deploy.sh`.

## 1. Create a Google Play service account

1. Go to [Google Play Console](https://play.google.com/console) → Setup → API access
2. Click **Link to a Google Cloud project** (or create one)
3. In Google Cloud Console → IAM & Admin → Service Accounts → **Create Service Account**
   - Name: `outcall-fastlane`
   - Role: none (assigned in Play Console)
4. Create a JSON key for the service account → Download it
5. Back in Play Console → Users & Permissions → Invite new users
   - Paste the service account email
   - Grant **Release manager** permission for `com.neo3151.huntingcalls`

## 2. Place the key file

Save the downloaded JSON key as:
```
android/fastlane/play-store-key.json
```

This file is gitignored — never commit it.

## 3. Run a deploy

```bash
# Bump version, build AAB, upload to production
./deploy.sh

# Upload to internal test track first (recommended)
./deploy.sh --internal

# Build only, upload manually via Play Console web UI
./deploy.sh --build-only
```

## Notes

- `versionCode` and `versionName` are auto-incremented in `pubspec.yaml` each run
- Signing uses `android/key.properties` (already configured)
- The AAB ends up at `build/app/outputs/bundle/release/app-release.aab`
