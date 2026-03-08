# Detailed Implementation Quirks

## 1. The DI Matrix & Mocking Strategy
The repository relies on `di_providers.dart` to determine what services are injected.
- The `isMock` boolean controls whether we use `mock_auth_repository` or actual cloud services.
- This **MUST NOT** be set to true in production releases.
- The `PlatformEnvironment` is critical for Riverpod. When `Platform.isLinux` is true, we CANNOT use `Firebase.initializeApp()` normally for Auth. We rely entirely on the `FiredartAuthRepository` and `sqflite_common_ffi` implementations instead.

## 2. The Rating Algorithm Cleanup
The application evaluates user calls against reference audio (`RatingResult`). 
- **FFT Extraction:** Spectrogram comparison logic requires careful memory management.
- **Cleanup:** We must specifically destroy `cloud_audio_service` instances on route pops to prevent memory leaks during spectrogram generation.

## 3. Universal UX & Accessibility
- **Targeting iOS App Store Compliance.**
- **Rules:**
  - Minimum 14pt (16pt+ preferred) font size.
  - 48x48 minimum touch target size.
  - No default Material alert dialogs; always use consistent `showModalBottomSheet` with custom theme and glassmorphism.
  - Semantic labels for all image assets to improve field readability and ScreenReader support.

## 4. Achievement Calculation Race Condition
- **Issue:** Previously earned achievements were being displayed as "newly earned" after an analysis.
- **Cause:** `RatingScreen` was checking for achievements using a stale profile state before the `saveResult` process (which is async and involves multiple Firestore writes/reloads) had fully completed.
- **Resolution:** Modified `_checkForAchievements` to be `async` and enforced a strict sequence: `loadProfile()` → calculate achievements → `saveAchievements()` → final `loadProfile()`. This ensures the UI only celebrates genuinely new unlocks against the most up-to-date data.
