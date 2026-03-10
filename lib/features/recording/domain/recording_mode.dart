import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The two recording modes available to users.
///
/// [quickMatch] — BirdNET + fingerprinting. Instant "what animal + basic % match".
/// [expert]     — Full detailed scoring, wave sync, AI coach, and specific tips.
enum RecordingMode { quickMatch, expert }

/// Riverpod provider that holds the current recording mode.
/// Defaults to [RecordingMode.quickMatch] for a casual-first experience.
class RecordingModeNotifier extends Notifier<RecordingMode> {
  @override
  RecordingMode build() => RecordingMode.quickMatch;

  void setMode(RecordingMode mode) {
    state = mode;
  }

  void toggle() {
    state = state == RecordingMode.quickMatch
        ? RecordingMode.expert
        : RecordingMode.quickMatch;
  }
}

final recordingModeProvider =
    NotifierProvider<RecordingModeNotifier, RecordingMode>(
        RecordingModeNotifier.new);
