# Recording Session Logic & Duration Hardening

The practice and recording session in Outcall requires strict lifecycle management to prevent "runaway" recordings that can occur if the user switches tabs or if the UI-level auto-stop timer fails.

## 1. Practice Mode Selection
To maintain a unified "luxury" feel, the **Practice tab** uses the same 3-tier grid navigation as the Library screen.
- **Selection Mode:** Triggered via `selectionMode: true` on `CategoryGridScreen`.
- In this mode, tapping a call in `AnimalCallsScreen` returns the `call.id` to the `RecorderPage` via `Navigator.pop(result)`.

## 2. Hardening Recording Duration Limits
A critical requirement is that all practice recordings must auto-stop within a few seconds of the reference call's ideal completion time. This prevents recordings from continuing indefinitely (e.g. 5 minutes for an 8-second call).

### 2.1 UI-level Auto-Stop Timer
The `RecorderPage` maintains a `_autoStopTimer` which is calculated as `(call.idealDurationSec + 2).clamp(3, 60)`. 
- **The Problem:** UI timers can be unreliable if the widget enters a background state (e.g. when hosted in a `PageView` and the user switches tabs). In some versions, the `MainShell` was found to keep the practice tab's state alive while it was recording, but UI timers might not fire as expected if the app's focus changes.

### 2.2 Controller-level Hard Max Duration (Nuclear Failsafe)
To ensure recordings always stop, a hard duration limit should be implemented at the `RecordingNotifier` (controller) level.
- **Mechanism:** `RecordingNotifier` calculates a `maxDurationSec` (e.g. `idealDurationSec + 3`, with a hard ceiling of 65s) upon starting a recording.
- **Enforcement:** In the `_startTimer` periodic tick, the controller checks `state.recordDuration >= _maxDuration`. If exceeded, it immediately calls `stopRecording()`.
- This ensures that even if the UI timer fails, the recording will never exceed a reasonable duration.

## 3. Tab Switching Cleanup
In the `MainShell._onPageChanged` hook, the `RecordingNotifier.reset()` method must be called to immediately stop any active recordings or countdowns when the user navigates away from the Practice tab. This mirrors the `AudioService.stop()` implementation for playback.

## Summary of Duration Rules
| Scenario | Behavior |
| :--- | :--- |
| **Normal Practice** | Auto-stop at `idealDurationSec + 2s`. |
| **UI Timer Failure** | Controller-level hard limit stops at `idealDurationSec + 3s`. |
| **Absolute Maximum** | Hard ceiling of 65 seconds for any recording. |
| **Switching Tabs** | Stop recording immediately. |
