# Android Keystore Setup Guide

This guide walks you through creating a production keystore for signing your Android release builds.

## Prerequisites

- Java Development Kit (JDK) installed
- Access to command line/terminal

## Step 1: Generate the Keystore

Run this command in your terminal:

```bash
keytool -genkey -v -keystore ~/upload-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias upload
```

**For Windows PowerShell:**
```powershell
keytool -genkey -v -keystore $env:USERPROFILE\upload-keystore.jks `
  -keyalg RSA -keysize 2048 -validity 10000 `
  -alias upload
```

You'll be prompted for:
- **Keystore password**: Choose a strong password (save this!)
- **Key password**: Choose another strong password (save this!)
- **Name, Organization, etc.**: Fill in your details

## Step 2: Create key.properties File

Create a file named `key.properties` in the `android/` directory:

```properties
storePassword=YOUR_KEYSTORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=upload
storeFile=C:/Users/YourUsername/upload-keystore.jks
```

**Important**: Replace the values with your actual passwords and file path.

For Linux/Mac, the path would be:
```properties
storeFile=/Users/YourUsername/upload-keystore.jks
```

## Step 3: Secure the key.properties File

Add this line to your `.gitignore` (if not already present):

```
android/key.properties
```

**Never commit your keystore or passwords to version control!**

## Step 4: Enable Signing in build.gradle.kts

Open `android/app/build.gradle.kts` and uncomment the signing configuration block (around line 45).

The configuration is already prepared - just remove the `/*` and `*/` comment markers.

## Step 5: Update buildTypes

In the same file, change the release buildType to use the release signing config:

```kotlin
buildTypes {
    release {
        signingConfig = signingConfigs.getByName("release")
    }
}
```

## Step 6: Test the Configuration

Build a release APK to verify everything works:

```bash
flutter clean
flutter pub get
flutter build apk --release
```

If successful, your signed APK will be at:
```
build/app/outputs/flutter-apk/app-release.apk
```

## Security Best Practices

1. **Backup your keystore**: Store it in a secure location (password manager, encrypted drive)
2. **Never share**: Don't email or share your keystore file
3. **Document passwords**: Store passwords securely (password manager recommended)
4. **Version control**: Ensure `.gitignore` excludes `key.properties` and `*.jks` files

## Troubleshooting

**"keytool: command not found"**
- Ensure JDK is installed and in your PATH
- Try using the full path: `C:\Program Files\Java\jdk-XX\bin\keytool.exe`

**"Keystore file not found"**
- Check the `storeFile` path in `key.properties`
- Use absolute paths, not relative paths
- On Windows, use forward slashes: `C:/Users/...`

**"Wrong password"**
- Verify you're using the correct keystore and key passwords
- Passwords are case-sensitive

## For Google Play Store

When uploading to Google Play:
1. Google Play will ask for your keystore on first upload
2. They'll manage app signing going forward (Play App Signing)
3. You'll use an "upload key" (this keystore) for future updates
4. Keep your keystore safe - you'll need it for all future updates!

## Next Steps

Once configured:
1. Build your release APK
2. Test it on a physical device
3. Upload to Google Play Console
4. Follow Google's app review process

---

**Need help?** Check the [Android documentation](https://developer.android.com/studio/publish/app-signing) for more details.
