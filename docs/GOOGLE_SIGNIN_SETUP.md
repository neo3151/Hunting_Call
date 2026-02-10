# Google Sign-In Setup Guide

Google Sign-In is currently **temporarily disabled** to allow the app to launch. Follow these steps to properly configure and re-enable it.

## Why It's Disabled

Google Sign-In on Android requires SHA-1 certificate fingerprints to be registered in Firebase Console. Without this, the app crashes on startup when Google Sign-In tries to initialize.

## Steps to Re-Enable Google Sign-In

### Step 1: Get Your SHA-1 Certificate Fingerprint

#### For Debug Builds:
```bash
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
```

**On Windows:**
```powershell
keytool -list -v -keystore $env:USERPROFILE\.android\debug.keystore -alias androiddebugkey -storepass android -keypass android
```

#### For Release Builds:
```bash
keytool -list -v -keystore ~/upload-keystore.jks -alias upload
```

Look for the **SHA-1** fingerprint in the output. It will look like:
```
SHA1: AA:BB:CC:DD:EE:FF:00:11:22:33:44:55:66:77:88:99:AA:BB:CC:DD
```

### Step 2: Add SHA-1 to Firebase Console

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: **hunting-call-perfection**
3. Click the gear icon ⚙️ > **Project settings**
4. Scroll down to **Your apps** section
5. Find your Android app: `com.neo3151.huntingcalls`
6. Click **Add fingerprint**
7. Paste your SHA-1 fingerprint
8. Click **Save**

**Important:** Add BOTH debug and release SHA-1 fingerprints if you want Google Sign-In to work in both builds.

### Step 3: Download Updated google-services.json

1. In Firebase Console, after adding the SHA-1
2. Click **Download google-services.json**
3. Replace the file at: `android/app/google-services.json`

The new file will include OAuth client configuration in the `oauth_client` array.

### Step 4: Re-Enable Google Sign-In in Code

Open `lib/features/auth/presentation/login_screen.dart` and find line ~210:

**Change from:**
```dart
if (false && !Platform.isWindows && !Platform.isLinux) ...[
```

**To:**
```dart
if (!Platform.isWindows && !Platform.isLinux) ...[
```

Simply remove the `false &&` part.

### Step 5: Rebuild and Test

```bash
flutter clean
flutter pub get
flutter build apk --release
```

Install the new APK on your device and test Google Sign-In!

---

## Troubleshooting

### "Sign in failed" or "Error 10"
- Make sure you added the SHA-1 for the keystore you're using
- Wait 5-10 minutes after adding SHA-1 for Firebase to propagate changes
- Download the updated `google-services.json`

### "Developer Error" or "Error 12501"
- Your Web Client ID might be incorrect
- Check Firebase Console > Authentication > Sign-in method > Google
- Make sure Google Sign-In is **enabled**

### Still Crashing
- Check that `google-services.json` has your package name: `com.neo3151.huntingcalls`
- Verify the OAuth client array is not empty in `google-services.json`
- Try uninstalling the app completely and reinstalling

---

## Current Configuration

**Package Name:** `com.neo3151.huntingcalls`  
**Firebase Project:** hunting-call-perfection  
**Web Client ID:** `654995904748-4ng8c4m5k870eo0qjkjb991v5u2igmo1.apps.googleusercontent.com`

**Status:** ⚠️ Google Sign-In temporarily disabled (missing SHA-1 configuration)

Once you complete the steps above, Google Sign-In will work perfectly! 🎉
