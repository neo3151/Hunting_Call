# 🪟 Windows Build Instructions for Hunting Calls Perfection

## 📋 Prerequisites

Before you can build the Windows executable, you need to install the following:

### 1. Flutter SDK (Required)
- **Download**: https://docs.flutter.dev/get-started/install/windows
- **Version**: 3.0.0 or higher
- **Installation Steps**:
  1. Download the Flutter SDK zip file
  2. Extract to `C:\src\flutter` (or your preferred location)
  3. Add Flutter to your PATH:
     - Search for "Environment Variables" in Windows
     - Edit PATH and add: `C:\src\flutter\bin`
  4. Restart your terminal/command prompt

### 2. Visual Studio 2022 (Required for Windows builds)
- **Download**: https://visualstudio.microsoft.com/downloads/
- **Edition**: Community (free) or higher
- **Required Workloads**:
  - ✅ Desktop development with C++
  - ✅ Windows 10/11 SDK

**Installation Steps**:
1. Download Visual Studio Installer
2. Select "Desktop development with C++"
3. In the right panel, ensure these are checked:
   - MSVC v143 - VS 2022 C++ x64/x86 build tools
   - Windows 10 SDK or Windows 11 SDK
   - C++ CMake tools for Windows
4. Click Install (this may take 30-60 minutes)

### 3. Git (Optional but recommended)
- **Download**: https://git-scm.com/download/win
- Used for version control and cloning repositories

---

## 🚀 Quick Start - Build Steps

### Option A: Using the Build Script (Easiest)

1. **Open Command Prompt or PowerShell**
   - Press `Win + R`
   - Type `cmd` or `powershell`
   - Navigate to the project folder:
     ```cmd
     cd path\to\Hunting_Call-main
     ```

2. **Run the build script**
   
   For Command Prompt:
   ```cmd
   build_windows.bat
   ```
   
   For PowerShell:
   ```powershell
   .\build_windows.ps1
   ```
   
   **Note for PowerShell**: If you get an execution policy error, run:
   ```powershell
   Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
   ```

3. **Wait for the build to complete** (5-15 minutes first time)

4. **Find your executable**:
   - Location: `build\windows\x64\runner\Release\`
   - File: `hunting_calls_perfection.exe`

---

### Option B: Manual Build (Step by Step)

If you prefer to understand each step or the script doesn't work:

#### Step 1: Verify Flutter Installation
```cmd
flutter --version
flutter doctor
```

**Expected output**:
- Flutter version 3.0.0 or higher
- All checkmarks for Windows development (Visual Studio, Windows SDK)

**If you see issues**:
```cmd
flutter doctor -v
```
This shows detailed information about missing components.

#### Step 2: Enable Windows Desktop Support
```cmd
flutter config --enable-windows-desktop
```

#### Step 3: Navigate to Project Directory
```cmd
cd path\to\Hunting_Call-main
```

#### Step 4: Clean Previous Builds (if any)
```cmd
flutter clean
```

#### Step 5: Get Dependencies
```cmd
flutter pub get
```

This downloads all required packages (~2-3 minutes).

#### Step 6: Generate Code Files
```cmd
flutter pub run build_runner build --delete-conflicting-outputs
```

This generates JSON serialization code for the profile and rating models.

#### Step 7: Build for Windows
```cmd
flutter build windows --release
```

**Build time**: 10-20 minutes (first build), 2-5 minutes (subsequent builds)

**Output location**: `build\windows\x64\runner\Release\`

---

## 📦 What Gets Built

After a successful build, you'll find these files in `build\windows\x64\runner\Release\`:

```
Release/
├── hunting_calls_perfection.exe  ⬅️ Main executable (10-20 MB)
├── flutter_windows.dll           ⬅️ Flutter engine (10-15 MB)
├── *.dll                          ⬅️ Other required DLLs
└── data/                          ⬅️ Assets folder
    ├── app.so                     ⬅️ Compiled Dart code
    ├── icudtl.dat                 ⬅️ ICU data
    └── flutter_assets/            ⬅️ Your app assets
        ├── assets/
        │   ├── audio/              ⬅️ Animal call audio files (13 MB)
        │   └── images/             ⬅️ Images
        ├── fonts/
        └── packages/
```

**Total size**: ~40-60 MB

---

## 🎯 Running the App

### From the Build Location
```cmd
cd build\windows\x64\runner\Release
hunting_calls_perfection.exe
```

### Creating a Desktop Shortcut
1. Navigate to `build\windows\x64\runner\Release\`
2. Right-click `hunting_calls_perfection.exe`
3. Click "Create shortcut"
4. Move the shortcut to your Desktop

---

## 📤 Creating a Distributable Package

To share the app with others or install it on another machine:

### Method 1: ZIP Archive (Recommended)
1. Navigate to `build\windows\x64\runner\`
2. Right-click the `Release` folder
3. Select "Send to" → "Compressed (zipped) folder"
4. Rename to `HuntingCallsPerfection-v1.0.0-Windows.zip`

**Important**: The entire `Release` folder must be distributed together. The .exe won't work without the DLLs and data folder.

### Method 2: Installer (Advanced)
Use tools like:
- **Inno Setup** (free): https://jrsoftware.org/isinfo.php
- **NSIS** (free): https://nsis.sourceforge.io/
- **Advanced Installer** (paid): https://www.advancedinstaller.com/

I can create an Inno Setup script for you if needed.

---

## 🐛 Troubleshooting

### Problem: "flutter: command not found"
**Solution**:
1. Make sure Flutter is installed
2. Check that Flutter is in your PATH:
   ```cmd
   echo %PATH%
   ```
3. Restart your terminal after adding Flutter to PATH

### Problem: "Visual Studio not found" or "CMake error"
**Solution**:
1. Install Visual Studio 2022 with C++ workload
2. Run:
   ```cmd
   flutter doctor -v
   ```
3. Look for detailed error messages
4. Ensure "Desktop development with C++" is installed

### Problem: "Building for x64, but only x86 found"
**Solution**:
Make sure you installed the x64 build tools in Visual Studio:
1. Open Visual Studio Installer
2. Click "Modify" on your installation
3. Ensure "MSVC v143 - VS 2022 C++ x64/x86 build tools" is checked

### Problem: Build fails with "error C2440" or other C++ errors
**Solution**:
1. Update Flutter:
   ```cmd
   flutter upgrade
   ```
2. Clean and rebuild:
   ```cmd
   flutter clean
   flutter pub get
   flutter build windows --release
   ```

### Problem: App crashes on startup
**Solution**:
1. Make sure all DLLs are in the same folder as the .exe
2. Check that the `data` folder is present
3. Run from command prompt to see error messages:
   ```cmd
   .\hunting_calls_perfection.exe
   ```

### Problem: Audio files not found
**Solution**:
The audio assets are in `data/flutter_assets/assets/audio/`. Make sure this folder structure is intact.

### Problem: "Waiting for another flutter command to release the startup lock"
**Solution**:
Another Flutter process is running. Either:
1. Wait for it to finish
2. Or force close and delete the lock file:
   ```cmd
   del %LOCALAPPDATA%\flutter\.flutter_tool_state.lock
   ```

---

## 🔧 Advanced Build Options

### Debug Build (for development)
```cmd
flutter build windows --debug
```
- Faster to build
- Larger file size
- Includes debugging symbols
- Located in: `build\windows\x64\runner\Debug\`

### Profile Build (for performance testing)
```cmd
flutter build windows --profile
```
- Includes performance profiling tools
- Medium file size

### Custom Build Configuration
```cmd
flutter build windows --release --dart-define=FLAVOR=production
```

---

## 📊 Build Performance Tips

### First Build (Clean System)
- Time: 15-25 minutes
- Downloads dependencies
- Compiles all native code

### Subsequent Builds
- Time: 2-5 minutes
- Only rebuilds changed code

### Speed Up Builds
1. **Use SSD**: Store project on SSD instead of HDD
2. **Exclude from Antivirus**: Add Flutter folder to antivirus exclusions
3. **Close Other Apps**: Free up RAM and CPU
4. **Use --no-tree-shake-icons**: Skip icon tree-shaking
   ```cmd
   flutter build windows --release --no-tree-shake-icons
   ```

---

## 🎨 Customizing the Build

### Change App Icon
1. Replace icon file in: `windows/runner/resources/app_icon.ico`
2. Use 256x256 PNG converted to ICO format
3. Rebuild

### Change App Name
Edit `windows/runner/Runner.rc`:
```c
VALUE "ProductName", "Your Custom Name"
VALUE "FileDescription", "Your Description"
```

### Change Version Number
Edit `pubspec.yaml`:
```yaml
version: 1.0.1+2  # version+buildNumber
```

---

## 📝 Build Checklist

Before distributing your app:

- [ ] Flutter doctor shows no errors
- [ ] All tests pass (`flutter test`)
- [ ] App runs without crashes
- [ ] Audio playback works
- [ ] Recording works
- [ ] All screens accessible
- [ ] Version number updated in `pubspec.yaml`
- [ ] Release notes prepared
- [ ] All files included in package:
  - [ ] .exe file
  - [ ] All DLL files
  - [ ] data/ folder
  - [ ] flutter_assets/ folder

---

## 📞 Getting Help

If you encounter issues:

1. **Check Flutter Doctor**:
   ```cmd
   flutter doctor -v
   ```

2. **Search Flutter Issues**: 
   https://github.com/flutter/flutter/issues

3. **Stack Overflow**:
   Tag: `flutter` + `windows`

4. **Flutter Discord**:
   https://discord.gg/flutter

---

## 🎉 Success!

Once built successfully, you can:
- Run the app locally
- Share the Release folder with others
- Create an installer
- Publish to Microsoft Store (requires additional setup)

**Congratulations on building your Windows app!** 🦌🎯

---

**Last Updated**: February 3, 2026
**Flutter Version Required**: 3.0.0+
**Visual Studio Version**: 2022
