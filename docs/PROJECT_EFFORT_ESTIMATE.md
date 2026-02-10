# Hunting Call — Traditional Development Effort Estimate

*Estimated: February 10, 2026 | Checkpoint: commit `5068fd2`*

## Component Breakdown

| Component | Solo Dev Estimate |
|---|---|
| **Flutter app architecture** (Riverpod, routing, state management, models) | 2-3 weeks |
| **Audio system** (50 animal calls, recording, playback, analysis engine) | 3-4 weeks |
| **Firebase integration** (Auth, Firestore, profiles, cloud sync) | 1-2 weeks |
| **Google Sign-In** (OAuth flow, profile dedup, race conditions) | 1 week |
| **UI/UX** (home screen, practice flow, library, hunting log, weather, onboarding, rating) | 3-4 weeks |
| **Profile system** (creation, switching, achievements, streaks, history) | 1-2 weeks |
| **Audio asset sourcing & optimization** (finding, downloading, normalizing 50 WAV files) | 1 week |
| **Daily challenges & gamification** | 1 week |
| **Cross-platform support** (Android + Windows, conditional features) | 1 week |
| **Testing, debugging, APK builds** | 1-2 weeks |

## Totals

- **Solo developer (full-time):** ~4-5 months
- **Small team (2-3 devs):** ~6-8 weeks

## Notable Observations

The Google Sign-In race condition bug — involving `onAuthStateChanged` timing, widget lifecycle, and Firestore writes — would typically take a developer 2-3 days to diagnose and fix. This was resolved in a single AI pair programming session.
