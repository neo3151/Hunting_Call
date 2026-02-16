# Gobble Guru — Release Candidate Checklist

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

### 1. Compile Errors (2/2)
- [x] `test/widget_test.dart` — Fixed missing ProviderScope/Riverpod imports
- [x] `lib/services/auth_service.dart` — Resolved (File is obsolete/dead after Clean Architecture migration)

### 2. Debug Cleanup
- [x] Initial cleanup of excessive `debugPrint` logs in `main_common.dart` and `auth_controller.dart`
- [x] Deeper cleanup of verbose logs across presentation and repository layers
- [x] Remove debug UI elements if any remain — confirmed clean (banner off, no debug borders)

### 3. App Signing
- [x] Set up proper release signing key (`upload-keystore.jks` via `key.properties`)
- [x] Configure `key.properties` for release builds

---

## ⚠️ Should Fix (Quality)

### 4. Code Warnings
- [x] Fix deprecated `withOpacity` calls → already migrated to `withValues(alpha:)`
- [x] Remove unused imports (6 across di_providers, call_detail, profile_controller, recorder, providers)
- [x] Fix null-check warnings in `firedart_profile_repository.dart`

### 5. APK Size Optimization
- [x] Audio assets are only 11MB — bulk is NDK native libraries
- [x] Enable ProGuard/R8 shrinking (`isMinifyEnabled=true`, `isShrinkResources=true`)
- [x] Consider splitting APK by ABI (`--split-per-abi`) for smaller downloads ✅ (arm64: 114MB, armv7: 112MB, x86_64: 116MB)

### 6. Error Handling
- [x] Timeout handling for all Firestore operations (10s reads + writes)
- [x] Graceful offline behavior UI — `ConnectivityBanner` widget in `BackgroundWrapper`

---

## 📱 Play Store Requirements

### 7. Store Listing Assets
- [x] App icon finalized — Gobble Guru branded (gold turkey on dark green) via `flutter_launcher_icons`
- [x] Feature graphic (1024x500) — saved to `docs/feature_graphic.png`
- [x] Screenshots (phone + tablet)
- [x] App description and metadata — `docs/PLAY_STORE_LISTING.md`

### 8. Play Console Setup
- [x] Create app listing in Google Play Console
- [x] Set up internal testing track
- [x] Privacy policy URL — `https://hunting-call-perfection.web.app/privacy-policy.html`
- [x] Content rating questionnaire
- [x] Target audience declaration

### 9. App Configuration
- [x] Set proper `versionCode` and `versionName` in build config (`1.3.0+4`)
- [x] Set correct `applicationId` (`com.neo3151.huntingcalls`)
- [x] Verify permissions are minimal (microphone, internet, location for geo-tagging)
