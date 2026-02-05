# CLAUDE.md - AI Assistant Guide for Hunting Calls Perfection

## Project Overview

**Hunting Calls Perfection** is a cross-platform Flutter mobile application that helps hunters improve their animal calling techniques through real-time audio analysis and feedback.

- **Package name**: `hunting_calls_perfection`
- **Version**: 1.0.1+1
- **Platforms**: Android, iOS, Windows, Linux
- **Dart SDK**: >=3.0.0 <4.0.0

## Codebase Structure

```
lib/
├── main.dart                    # App entry point, Firebase init, global error handling
├── injection_container.dart     # Dependency injection setup using GetIt
├── core/
│   ├── theme/
│   │   └── theme_notifier.dart  # Legacy theme state (ChangeNotifier)
│   └── widgets/
│       └── background_wrapper.dart  # Reusable background widget
├── theme/
│   └── app_theme.dart           # Dark theme definition (Material 3)
├── providers/
│   ├── providers.dart           # Central export for all providers
│   ├── auth_provider.dart       # Authentication state (Riverpod)
│   ├── profile_provider.dart    # User profile state (Riverpod Notifier)
│   ├── recording_provider.dart  # Recording state
│   ├── rating_provider.dart     # Rating/scoring state
│   └── onboarding_provider.dart # Onboarding flow state
└── features/                    # Feature-based architecture
    ├── analysis/                # Audio analysis & FFT processing
    │   ├── data/
    │   │   ├── comprehensive_audio_analyzer.dart  # Full audio analysis
    │   │   ├── fftea_frequency_analyzer.dart      # FFT implementation
    │   │   ├── real_rating_service.dart           # Scoring algorithm
    │   │   └── waveform_cache_database.dart       # SQLite waveform cache
    │   ├── domain/
    │   │   ├── audio_analysis_model.dart          # Analysis data model
    │   │   └── frequency_analyzer.dart            # Analyzer interface
    │   └── presentation/
    │       ├── audio_analytics_display.dart
    │       └── widgets/
    ├── auth/                    # Authentication
    │   ├── data/
    │   │   ├── firebase_auth_repository.dart  # Firebase auth impl
    │   │   └── mock_auth_repository.dart      # Offline/mock auth
    │   ├── domain/
    │   │   └── auth_repository.dart           # Auth interface
    │   └── presentation/
    │       ├── auth_wrapper.dart
    │       └── login_screen.dart
    ├── daily_challenge/         # Daily challenge feature
    │   └── data/
    │       └── daily_challenge_service.dart
    ├── home/                    # Home/dashboard screen
    │   └── presentation/
    │       └── home_screen.dart
    ├── leaderboard/             # Leaderboard feature
    ├── library/                 # Reference call library
    │   ├── data/
    │   │   └── reference_database.dart        # Animal call database
    │   ├── domain/
    │   │   └── reference_call_model.dart      # Reference call model
    │   └── presentation/
    │       ├── library_screen.dart
    │       └── call_detail_screen.dart
    ├── onboarding/              # First-time user onboarding
    ├── profile/                 # User profiles & achievements
    │   ├── data/
    │   │   ├── profile_repository.dart        # Repository interface
    │   │   ├── firestore_profile_repository.dart
    │   │   └── local_profile_data_source.dart
    │   ├── domain/
    │   │   ├── profile_model.dart             # User profile model
    │   │   └── achievement_service.dart       # Achievement logic
    │   └── presentation/
    │       └── profile_screen.dart
    ├── progress_map/            # Field map with recording locations
    ├── rating/                  # Call rating & feedback
    │   ├── domain/
    │   │   ├── rating_model.dart              # Rating result model
    │   │   ├── rating_service.dart            # Rating service interface
    │   │   └── personality_feedback_service.dart
    │   └── presentation/
    │       ├── rating_screen.dart
    │       └── widgets/
    ├── recording/               # Audio recording
    │   ├── data/
    │   │   ├── real_audio_recorder_service.dart
    │   │   └── mock_audio_recorder_service.dart
    │   ├── domain/
    │   │   └── audio_recorder_service.dart    # Recorder interface
    │   └── presentation/
    │       ├── recorder_page.dart
    │       └── widgets/
    │           └── live_visualizer.dart
    └── splash/                  # Splash screen
        └── presentation/
            └── splash_screen.dart
```

## Architecture Patterns

### Feature-Based Architecture
Each feature follows a consistent **data/domain/presentation** structure:
- `data/` - Repositories, services, data sources (implementations)
- `domain/` - Models, interfaces, business logic
- `presentation/` - Screens, widgets, UI components

### State Management
The app uses a **hybrid approach** during migration:
- **Flutter Riverpod** (`flutter_riverpod`) - Primary state management for new code
- **Provider** (`provider`) - Legacy, kept for ThemeNotifier during migration
- **GetIt** - Service locator for dependency injection

### Dependency Injection Pattern
```dart
// injection_container.dart uses GetIt
final sl = GetIt.instance;

// Services are registered as lazy singletons
sl.registerLazySingleton<AuthRepository>(() => FirebaseAuthRepository());
```

### Repository Pattern
Abstract interfaces in `domain/`, implementations in `data/`:
```dart
// domain/auth_repository.dart
abstract class AuthRepository {
  Future<void> signIn(String userId);
  Stream<String?> get onAuthStateChanged;
}

// data/firebase_auth_repository.dart
class FirebaseAuthRepository implements AuthRepository { ... }
```

### Riverpod Provider Pattern
```dart
// State class
class ProfileState {
  final UserProfile? profile;
  final bool isLoading;
  final String? error;
}

// Notifier class
class ProfileNotifier extends Notifier<ProfileState> {
  @override
  ProfileState build() => const ProfileState();
}

// Provider
final profileNotifierProvider = NotifierProvider<ProfileNotifier, ProfileState>(...);
```

## Key Dependencies

| Package | Purpose |
|---------|---------|
| `flutter_riverpod` | State management |
| `get_it` | Dependency injection |
| `record` | Audio recording (cross-platform) |
| `audioplayers` | Audio playback |
| `fftea` | FFT frequency analysis |
| `firebase_core/auth` | Authentication (optional) |
| `cloud_firestore` | Cloud data storage (optional) |
| `shared_preferences` | Local persistence |
| `sqflite` | SQLite database (waveform cache) |
| `google_fonts` | Typography (Oswald, Lato) |
| `geolocator` | Location for Field Map |
| `flutter_map` | Map display |
| `json_annotation` | JSON serialization |

## Development Workflows

### Initial Setup
```bash
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

### Running the App
```bash
# Debug mode
flutter run

# Release mode
flutter run --release

# Specific platform
flutter run -d windows
flutter run -d android
```

### Building for Release

**Android APK:**
```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

**Windows:**
```bash
flutter clean
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
flutter build windows --release
# Output: build/windows/x64/runner/Release/
```

### Code Generation
The project uses `build_runner` for:
- JSON serialization (`*.g.dart` files)
- Riverpod code generation

```bash
# One-time build
flutter pub run build_runner build --delete-conflicting-outputs

# Watch mode (during development)
flutter pub run build_runner watch --delete-conflicting-outputs
```

### Running Tests
```bash
# All tests
flutter test

# Specific test file
flutter test test/rating_service_test.dart

# With coverage
flutter test --coverage
```

## Key Conventions

### File Naming
- Use `snake_case` for file names: `rating_screen.dart`, `audio_analysis_model.dart`
- Generated files use `.g.dart` suffix: `rating_model.g.dart`
- Test files use `_test.dart` suffix: `rating_service_test.dart`

### Code Style
- Dart standard formatting (use `dart format`)
- Use `const` constructors where possible
- Prefer named parameters for clarity
- Use `debugPrint` instead of `print` for debug output

### Widget Patterns
- Use `ConsumerWidget` or `ConsumerStatefulWidget` for Riverpod
- Prefix private methods with `_build` for widget builders
- Use `BackgroundWrapper` for consistent backgrounds
- Apply `ClipRRect` + `BackdropFilter` for glassmorphic effects

### Theme & Styling
- Primary color: `Color(0xFF5FF7B6)` (mint green)
- Dark theme only (currently)
- Typography: Oswald for headers, Lato for body text
- Material 3 enabled

### Audio Format
- Recording format: WAV PCM16
- Sample rate: 44100 Hz (default)
- Mono channel

## Firebase Integration

Firebase is **optional**. The app runs in "Off-Grid" mode without Firebase:
- Falls back to `MockAuthRepository` for auth
- Uses `LocalProfileRepository` for profile storage

To enable Firebase:
1. Add `google-services.json` (Android) or `GoogleService-Info.plist` (iOS)
2. Run `flutterfire configure`

## Testing Patterns

### Unit Tests
Use `mocktail` for mocking:
```dart
class MockFrequencyAnalyzer extends Mock implements FrequencyAnalyzer {}

void main() {
  late MockFrequencyAnalyzer mockAnalyzer;

  setUp(() {
    mockAnalyzer = MockFrequencyAnalyzer();
    when(() => mockAnalyzer.analyzeAudio(any())).thenAnswer(...);
  });
}
```

### Widget Tests
```dart
testWidgets('description', (WidgetTester tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [...],
      child: MaterialApp(home: MyWidget()),
    ),
  );
});
```

## Important Files

| File | Description |
|------|-------------|
| `lib/main.dart` | App entry, Firebase init, error handling |
| `lib/injection_container.dart` | DI setup, service registration |
| `lib/features/library/data/reference_database.dart` | Animal call reference data |
| `lib/features/analysis/data/real_rating_service.dart` | Core scoring algorithm |
| `lib/features/analysis/data/comprehensive_audio_analyzer.dart` | FFT analysis |
| `pubspec.yaml` | Dependencies and assets |
| `android/app/build.gradle.kts` | Android build config |

## Scoring Algorithm

The rating system in `real_rating_service.dart` works as follows:

1. **Analyze user audio** - Extract dominant frequency and duration
2. **Compare to reference** - Get ideal values from `ReferenceDatabase`
3. **Calculate scores**:
   - Pitch score (60% weight): Percentage deviation from ideal
   - Duration score (40% weight): Percentage deviation from ideal
4. **Generate feedback** based on score thresholds

## Common Tasks

### Adding a New Animal Call
1. Add audio file to `assets/audio/`
2. Add entry in `ReferenceDatabase` with ideal pitch/duration
3. Update `pubspec.yaml` assets if needed

### Adding a New Feature
1. Create feature folder under `lib/features/<feature_name>/`
2. Add `data/`, `domain/`, `presentation/` subdirectories
3. Create domain interfaces first, then implementations
4. Add providers to `lib/providers/`
5. Register services in `injection_container.dart`

### Modifying State
1. Update the `State` class with new fields
2. Update the `Notifier` class with new methods
3. Use `state = state.copyWith(...)` for immutable updates

## Known Issues & Notes

- `record_linux: 1.3.0` is pinned via dependency override for Linux compatibility
- Firebase initialization may fail silently; check debug logs
- Location permissions are requested at runtime for Field Map feature
- Waveform cache uses SQLite to avoid re-analyzing reference audio

## Assets Structure

```
assets/
├── audio/           # Animal call audio files (.wav, .ogg, .mp3)
├── images/          # App images, logos, screenshots
│   ├── logo.png
│   ├── forest_background.png
│   └── screenshots/
└── data/            # (Reserved for future data files)
```
