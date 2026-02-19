# 📋 Changelog - OUTCALL Updates

## Version 1.5.0 - February 18, 2026

### 🦅 Revolutionary Rebrand: Welcome to OUTCALL
- **Rebranded**: Transformed "Hunting Call" into **OUTCALL**.
- **Visuals**: Updated app icon, feature graphics, and Play Store assets.
- **Legal**: Added dedicated Privacy Policy page on GitHub Pages.

### 🛡️ Critical Fixes & Stability
- **Authentication**: Resolved the persistent Google Sign-In redirect loop. Sign-in is now seamless.
- **Analysis**: Fixed spectrogram overlay in practice mode. Real-time feedback is now crystal clear.
- **Version Control**: Implemented `VersionCheckService` to ensure users are always on the latest, most stable release.

### ✨ UI/UX Refinement
- **Layout**: Optimized animal image alignment in challenge cards and screens.
- **Onboarding**: Refined flow for a smoother first-time experience.
- **Build**: Incrementing to build `1.5.0+16` with optimized release configurations.

---

## Version 1.1.0 - February 10, 2026

### 🚀 Release Preparation

#### Configuration Updates
- **Changed**: Application ID from `com.example.hunting_calls_perfection` to `com.neo3151.huntingcalls`
- **Changed**: Android namespace updated to match new application ID
- **Added**: Comprehensive release signing configuration documentation in `build.gradle.kts`
- **Added**: Google Sign-In configured with production Web Client ID

#### Code Quality
- **Improved**: Error handling for unconfigured authentication methods
- **Added**: Clear instructions for production keystore setup
- **Documented**: Step-by-step guide for enabling Google Sign-In when ready

### 📦 What's Changed

```
android/app/build.gradle.kts              [UPDATED] ✨
lib/features/auth/data/firebase_auth_repository.dart  [UPDATED] 🔒
pubspec.yaml                              [UPDATED] 📦
CHANGELOG.md                              [UPDATED] 📋
```

### ⚠️ Breaking Changes
- Application ID changed - existing installations will be treated as a new app
- Google Sign-In temporarily disabled until Web Client ID is configured

### 🔧 For Developers

**To enable Google Sign-In:**
1. Get Web Client ID from Firebase Console
2. Update `firebase_auth_repository.dart` line 41
3. Uncomment the implementation code

**To configure production signing:**
1. Generate keystore: `keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload`
2. Create `android/key.properties` with credentials
3. Uncomment signing configuration in `build.gradle.kts`

---

## Version 1.0.1 - February 3, 2026

### 🐛 Bug Fixes

#### Rating Screen Display Fix
- **Fixed**: Metrics were displaying as percentages instead of actual measurements
- **Changed**: `lib/features/rating/presentation/rating_screen.dart`
- **Impact**: Users now see proper units (Hz for pitch, s for duration)

**Before:**
- Pitch (Hz): 479%
- Duration (s): 1%

**After:**
- Pitch (Hz): 479.0 Hz
- Duration (s): 1.20 s

### ✨ UI Enhancements

#### Rating Screen Visual Improvements
- Added glassmorphic card design for metrics
- Enhanced value display with highlighted boxes
- Added descriptive labels ("Your frequency", "Ideal frequency", "Call length")
- Improved spacing and visual hierarchy
- Better mobile and desktop layouts

### 📚 Documentation Added

#### Windows Build Documentation
- **Added**: `BUILD_INSTRUCTIONS_WINDOWS.md` - Comprehensive 200+ line build guide
- **Added**: `QUICK_REFERENCE.md` - Quick command reference card
- **Added**: `RATING_SCREEN_FIX_SUMMARY.md` - Detailed fix documentation

#### Build Scripts
- **Added**: `build_windows.bat` - Automated Windows build script (Command Prompt)
- **Added**: `build_windows.ps1` - PowerShell build script with color output

### 📦 What's Included

```
Hunting_Call-main/
├── lib/features/rating/presentation/
│   └── rating_screen.dart              [UPDATED] ✨
├── build_windows.bat                    [NEW] 🆕
├── build_windows.ps1                    [NEW] 🆕
├── BUILD_INSTRUCTIONS_WINDOWS.md        [NEW] 📖
├── QUICK_REFERENCE.md                   [NEW] 📖
├── RATING_SCREEN_FIX_SUMMARY.md        [NEW] 📖
└── CHANGELOG.md                         [NEW] 📋
```

### 🔧 Technical Details

#### Modified Components
- Rating screen widget structure
- Metric display logic
- Card layout system

#### New Methods Added
- `_buildMetricCard(String key, double value)` - Smart metric card builder
- `_getMetricDescription(String key)` - Returns helpful descriptions

#### Unit Detection Logic
```dart
if (key contains 'pitch' or 'hz')  → Display as Hz (1 decimal)
if (key contains 'duration' or 's') → Display as s (2 decimals)
else                                → Display raw number
```

### 🎯 Testing Recommendations

Before deploying, test:
- [ ] Duck call recording (low frequency)
- [ ] Elk bugle recording (high frequency)
- [ ] Various call durations
- [ ] All supported animals (11 types)
- [ ] Different screen sizes
- [ ] Light and dark themes

### 🚀 Deployment Instructions

#### Quick Deploy
1. Run `build_windows.bat` (Windows)
2. Executable will be in: `build\windows\x64\runner\Release\`
3. Distribute the entire Release folder

#### Manual Deploy
```bash
flutter clean
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
flutter build windows --release
```

### ⚠️ Breaking Changes
None - fully backward compatible

### 🔄 Migration Guide
No migration needed. Simply replace the `rating_screen.dart` file.

### 📊 Performance Impact
- Minimal (UI rendering only)
- No additional dependencies
- Same memory footprint
- Slightly better rendering with card-based layout

### 🐛 Known Issues
None reported with this update.

### 🙏 Acknowledgments
- User feedback for identifying the percentage display issue
- Flutter community for best practices

### 📞 Support
For issues or questions:
- Check `BUILD_INSTRUCTIONS_WINDOWS.md` for build problems
- Check `RATING_SCREEN_FIX_SUMMARY.md` for display issues
- Review `QUICK_REFERENCE.md` for quick commands

---

## Previous Versions

### Version 1.0.0 - Initial Release
- Core recording functionality
- FFT-based frequency analysis
- 11 animal call references
- Profile tracking system
- Cross-platform support (Windows, Linux, iOS, Android)

---

**Next Version Preview (1.1.0)**
Planned features:
- Firebase authentication integration
- Cloud profile sync
- Additional animal calls
- Advanced audio analysis
- Social features

---

**Last Updated**: February 3, 2026
**Maintainer**: Development Team
**License**: MIT
