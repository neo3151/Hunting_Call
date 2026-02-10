# Hunting Call — Release Candidate Checklist

## ✅ Working Features
- [x] Google Sign-In with profile creation and dedup
- [x] Local profile creation and switching
- [x] Home screen with user greeting
- [x] Audio library (50 animal calls)
- [x] Practice flow with recording
- [x] Audio analysis and rating
- [x] Daily challenges
- [x] Profile management (achievements, streaks, history)
- [x] Onboarding flow
- [x] Hunting log
- [x] Weather screen
- [x] Leaderboard
- [x] Cloud sync via Firestore
- [x] Cross-platform (Android + Windows)

---

## 🔧 Must Fix (Blockers)

### 1. Compile Errors (2)
- [ ] `lib/services/auth_service.dart` — undefined `authRepositoryProvider` reference
- [ ] `test/widget_test.dart` — `ProviderScope` not recognized as a class

### 2. Debug Cleanup
- [ ] Remove excess `debugPrint` statements from 20+ files (auth, profile, home, analysis)
- [ ] Remove debug UI elements if any remain (colored borders, banners)

### 3. App Signing
- [ ] Set up proper release signing key (not debug keystore)
- [ ] Configure `key.properties` for release builds

---

## ⚠️ Should Fix (Quality)

### 4. Code Warnings
- [ ] Fix deprecated `withOpacity` calls → use `withValues(alpha:)` (2 files)
- [ ] Remove unused imports (leaderboard, progress_map, injection_container, main)
- [ ] Fix null-check warnings in `firedart_profile_repository.dart`

### 5. APK Size Optimization
- [ ] Current APK is ~106MB — consider compressing audio assets further
- [ ] Enable ProGuard/R8 shrinking
- [ ] Consider splitting APK by ABI (`--split-per-abi`)

### 6. Error Handling
- [ ] Graceful offline behavior (no internet)
- [ ] Timeout handling for Firestore operations

---

## 📱 Play Store Requirements

### 7. Store Listing Assets
- [ ] App icon finalized (512x512 + adaptive icon)
- [ ] Feature graphic (1024x500)
- [ ] Screenshots (phone + tablet)
- [ ] App description and metadata

### 8. Play Console Setup
- [ ] Create app listing in Google Play Console
- [ ] Set up internal testing track
- [ ] Privacy policy URL
- [ ] Content rating questionnaire
- [ ] Target audience declaration

### 9. App Configuration
- [ ] Set proper `versionCode` and `versionName` in build config
- [ ] Set correct `applicationId` (package name)
- [ ] Verify permissions are minimal (microphone, internet only)
