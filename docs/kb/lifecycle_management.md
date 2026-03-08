# App Shell Lifecycle Management

In Outcall, the `MainShell` uses a `PageView` to host the primary features (Home, Library, Practice, etc.). Because `PageView` keeps inactive routes alive in the widget tree, standard screen-level `dispose()` methods do not fire when the user switches tabs. This creates "resource leaks" where audio or recordings continue playing/running in the background.

## 1. The Centralized Stop Pattern

To prevent leaks, all global services (Audio, Recording) must be hooked into the `MainShell` tab-switching logic.

### Implementation in `MainShell`:
- **MainShell as ConsumerStatefulWidget**: Converted to access Riverpod providers globally.
- **`_onPageChanged(int index)` Hook**: This is the single source of truth for tab transitions.

```dart
void _onPageChanged(int index) {
  // 1. Stop any playing reference audio
  ref.read(audioServiceProvider).stop();
  
  // 2. Kill any active recording or countdown sessions
  final recState = ref.read(recordingNotifierProvider);
  if (recState.isRecording || recState.isCountingDown) {
    ref.read(recordingNotifierProvider.notifier).reset();
  }
  
  setState(() {
    _currentIndex = index;
  });
}
```

## 2. Audio Playback Lifecycle
While the shell handles tab-switching, individual screens should still clean up if they are popped or replaced:
- `AnimalCallsScreen` and `CallDetailScreen` call `_audioService?.stop()` in their `dispose()` methods.
- They also use `RouteAware` (`didPushNext`) to stop audio when the user navigates deeper (e.g., from List to Detail).

## 3. Recording Session Lifecycle
Recording sessions are particularly "risky" because they can consume significant storage if left running.
- **Tab Switch Reset**: Always call `recordingNotifier.reset()` on tab switch.
- **Hard Failsafe**: In addition to the UI-level auto-stop timer, the `RecordingNotifier` implements a controller-level hard max duration (see `recording_logic.md`).

## 4. Best Practices for Navigation Hooks
- **Never rely solely on `dispose()`** for global cleanup if using `PageView` or cached `TabController` views.
- **Centralize Service Ownership**: Use Riverpod to ensure the shell can reach the same service instance that the screens are using.
- **Use Haptics on Switch**: The `MainShell` trigger (`_onBottomNavTapped`) should provide light haptic feedback to confirm the user's tab choice.
