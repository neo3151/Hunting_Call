# Adding SHA-1 to Firebase (When Ready)

Google Sign-In is now **enabled** in the app, but you'll need to add your SHA-1 certificate to Firebase Console for it to work properly.

## Why You Need SHA-1

Google Sign-In on Android requires SHA-1 certificate fingerprints for security. Without it, you'll get an error like "Error 10" or "Developer Error" when trying to sign in.

## How to Get SHA-1 (When You Have Time)

### Option 1: Using Terminal in Android Studio
1. Open Android Studio
2. Open Terminal (bottom of window)
3. Run:
   ```bash
   cd android
   gradlew signingReport
   ```
4. Look for "SHA1:" under "Variant: debug"
5. Copy that value

### Option 2: Using PowerShell (if you find keytool)
```powershell
# Find where keytool is installed
Get-ChildItem -Path "C:\Program Files" -Filter "keytool.exe" -Recurse -ErrorAction SilentlyContinue

# Then run (replace path):
& "C:\Path\To\keytool.exe" -list -v -keystore $env:USERPROFILE\.android\debug.keystore -alias androiddebugkey -storepass android -keypass android
```

## Adding SHA-1 to Firebase

Once you have your SHA-1:

1. Go to: https://console.firebase.google.com/
2. Select: **hunting-call-perfection**
3. Click gear ⚙️ > **Project settings**
4. Scroll to **Your apps**
5. Find: `com.example.hunting_calls_perfection`
6. Click **Add fingerprint**
7. Paste SHA-1
8. Click **Save**
9. **Download google-services.json** (important!)
10. Replace `android/app/google-services.json` with the new file
11. Rebuild the APK

## For Now

The app will build and run, but Google Sign-In will show an error until you add the SHA-1. You can still test all other features!

**When you're ready to add SHA-1, just let me know and I'll help you through it.**
