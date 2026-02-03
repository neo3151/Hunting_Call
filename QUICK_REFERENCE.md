# 🚀 Quick Reference - Build Commands

## Essential Commands

### First Time Setup
```cmd
# Verify Flutter installation
flutter doctor

# Enable Windows support
flutter config --enable-windows-desktop

# Get dependencies
flutter pub get

# Generate code
flutter pub run build_runner build --delete-conflicting-outputs
```

### Build Commands
```cmd
# Clean build
flutter clean

# Build release (optimized, smaller)
flutter build windows --release

# Build debug (faster, with debugging)
flutter build windows --debug

# Build profile (for performance testing)
flutter build windows --profile
```

### Run Commands
```cmd
# Run in debug mode (hot reload enabled)
flutter run -d windows

# Run in release mode
flutter run -d windows --release
```

### Maintenance Commands
```cmd
# Update Flutter
flutter upgrade

# Check for outdated packages
flutter pub outdated

# Update packages
flutter pub upgrade

# Analyze code
flutter analyze

# Run tests
flutter test
```

## Output Locations

| Build Type | Location |
|------------|----------|
| Release | `build\windows\x64\runner\Release\` |
| Debug | `build\windows\x64\runner\Debug\` |
| Profile | `build\windows\x64\runner\Profile\` |

## Common Issues Quick Fix

```cmd
# Issue: Build fails
flutter clean && flutter pub get && flutter build windows --release

# Issue: Flutter stuck
del %LOCALAPPDATA%\flutter\.flutter_tool_state.lock

# Issue: Dependencies conflict
flutter pub upgrade --major-versions

# Issue: Code generation fails
flutter pub run build_runner clean
flutter pub run build_runner build --delete-conflicting-outputs
```

## File Sizes (Approximate)

- Debug Build: ~150-200 MB
- Release Build: ~40-60 MB
- Compressed (ZIP): ~20-30 MB

## Build Time

- First Build: 15-25 minutes
- Incremental: 2-5 minutes
- Clean Build: 10-15 minutes

---

**Pro Tip**: Use `build_windows.bat` for automated one-click builds!
