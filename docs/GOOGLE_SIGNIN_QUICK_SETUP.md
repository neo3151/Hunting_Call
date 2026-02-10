# Quick Google Sign-In Setup

## Step 1: Get Your SHA-1 Fingerprint

### Option A: Using Android Studio (Easiest)
1. Open Android Studio
2. Open your project: `C:\Users\neo31\Hunting_Call`
3. Click **Gradle** tab on the right
4. Navigate to: `Hunting_Call > Tasks > android > signingReport`
5. Double-click `signingReport`
6. Look for **SHA1** under "Variant: debug" in the output
7. Copy the SHA1 value (looks like: `AA:BB:CC:DD:...`)

### Option B: Using Command Line
If you have Java installed, run this in PowerShell:

```powershell
& "C:\Program Files\Java\jdk-XX\bin\keytool.exe" -list -v -keystore $env:USERPROFILE\.android\debug.keystore -alias androiddebugkey -storepass android -keypass android
```

Replace `jdk-XX` with your actual JDK version folder.

Look for the line starting with `SHA1:` and copy that value.

---

## Step 2: Add SHA-1 to Firebase Console

1. Go to: https://console.firebase.google.com/
2. Select project: **hunting-call-perfection**
3. Click the gear icon ⚙️ > **Project settings**
4. Scroll to **Your apps** section
5. Find: **Hunting Calls Perfection** (`com.example.hunting_calls_perfection`)
6. Click **Add fingerprint**
7. Paste your SHA-1 fingerprint
8. Click **Save**

---

## Step 3: Download Updated google-services.json

1. Still in Firebase Console, same page
2. Click **Download google-services.json** button
3. Save it and **send it to me** (or paste its contents)
4. I'll update the file in your project

---

## Step 4: I'll Re-Enable Google Sign-In

Once you provide the updated `google-services.json`, I will:
1. Replace the current file
2. Remove the `false &&` from the login screen
3. Rebuild the APK
4. Google Sign-In will work! 🎉

---

## What You Need to Do Now

**Send me:**
1. Your SHA-1 fingerprint (from Step 1)
2. The updated `google-services.json` file contents (from Step 3)

Then I'll handle the rest!
