import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:outcall/core/services/logger/logger_service.dart';
import 'package:outcall/di_providers.dart';
import 'package:outcall/features/library/data/reference_database.dart';
import 'package:outcall/features/recording/domain/failures/recording_failure.dart';
import 'package:outcall/features/recording/domain/providers.dart';
import 'package:outcall/features/recording/domain/use_cases/start_recording_use_case.dart';
import 'package:outcall/features/recording/domain/use_cases/stop_recording_use_case.dart';

/// State for recording session
enum RecordingStatus { idle, countdown, recording, stopping, error }

class RecordingState {
  final RecordingStatus status;
  final String? audioPath;
  final RecordingFailure? failure; // Changed from String? error
  final int recordDuration;
  final int? countdownValue;

  const RecordingState({
    this.status = RecordingStatus.idle,
    this.audioPath,
    this.failure,
    this.recordDuration = 0,
    this.countdownValue,
  });

  bool get isRecording => status == RecordingStatus.recording;
  bool get isCountingDown => status == RecordingStatus.countdown;
  bool get hasError => status == RecordingStatus.error;

  // Convenience getter for error message
  String? get errorMessage => failure?.message;

  RecordingState copyWith({
    RecordingStatus? status,
    String? audioPath,
    RecordingFailure? failure,
    int? recordDuration,
    int? countdownValue,
    bool clearFailure = false,
    bool clearCountdown = false,
  }) {
    return RecordingState(
      status: status ?? this.status,
      audioPath: audioPath ?? this.audioPath,
      failure: clearFailure ? null : (failure ?? this.failure),
      recordDuration: recordDuration ?? this.recordDuration,
      countdownValue: clearCountdown ? null : (countdownValue ?? this.countdownValue),
    );
  }
}

/// Thin controller that delegates to use cases
class RecordingNotifier extends Notifier<RecordingState> {
  Timer? _timer;

  /// Hard ceiling on any recording, regardless of call duration.
  static const int _absoluteMaxSeconds = 65;

  /// Current max duration for this recording session.
  int _maxDurationSec = _absoluteMaxSeconds;

  @override
  RecordingState build() {
    ref.onDispose(() {
      _timer?.cancel();
    });
    return const RecordingState();
  }

  // Use cases injected via providers
  StartRecordingUseCase get _startUseCase => ref.read(startRecordingUseCaseProvider);
  StopRecordingUseCase get _stopUseCase => ref.read(stopRecordingUseCaseProvider);

  /// Set max recording duration based on the reference call's ideal length.
  /// Call this BEFORE startRecordingWithCountdown().
  void setMaxDuration(double idealDurationSec) {
    _maxDurationSec = (idealDurationSec + 3).clamp(5, _absoluteMaxSeconds).toInt();
  }

  /// Start recording with countdown
  Future<void> startRecordingWithCountdown() async {
    if (state.isRecording || state.isCountingDown) return;

    ref.read(loggerServiceProvider).log('Start recording pressed (countdown initiated)');
    state = state.copyWith(status: RecordingStatus.countdown, clearFailure: true);

    final fileName = 'hunting_call_${DateTime.now().millisecondsSinceEpoch}.wav';
    final outputPath = await ref.read(fileServiceProvider).getTemporaryPath(fileName);

    final result = await _startUseCase.execute(
      outputPath: outputPath,
      onCountdownTick: (value) {
        if (value > 0) {
          state = state.copyWith(
            status: RecordingStatus.countdown,
            countdownValue: value,
          );
        } else {
          state = state.copyWith(clearCountdown: true);
        }
      },
    );

    result.fold(
      // Error
      (failure) {
        ref
            .read(loggerServiceProvider)
            .recordError(failure, null, reason: 'Failed to start recording');
        state = state.copyWith(
          status: RecordingStatus.error,
          failure: failure,
          clearCountdown: true,
        );
      },
      // Success
      (audioPath) {
        ref.read(loggerServiceProvider).log('Recording actually started: $audioPath');
        state = state.copyWith(
          status: RecordingStatus.recording,
          clearCountdown: true,
          recordDuration: 0,
        );
        _startTimer();
      },
    );
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final newDuration = state.recordDuration + 1;
      state = state.copyWith(recordDuration: newDuration);

      // Hard failsafe: force-stop if max duration exceeded
      if (newDuration >= _maxDurationSec) {
        ref.read(loggerServiceProvider).log(
              '⏱️ Hard max duration (${_maxDurationSec}s) reached — force-stopping recording',
            );
        stopRecording();
      }
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  /// Stop recording
  Future<String?> stopRecording() async {
    _stopTimer();
    state = state.copyWith(status: RecordingStatus.stopping);

    final result = await _stopUseCase.execute();

    return result.fold(
      // Error
      (failure) {
        ref
            .read(loggerServiceProvider)
            .recordError(failure, null, reason: 'Failed to stop recording');
        state = state.copyWith(
          status: RecordingStatus.error,
          failure: failure,
        );
        return null;
      },
      // Success
      (audioPath) {
        ref.read(loggerServiceProvider).log('Recording stopped successfully: $audioPath');
        state = state.copyWith(
          status: RecordingStatus.idle,
          audioPath: audioPath,
        );
        return audioPath;
      },
    );
  }

  /// Reset state
  Future<void> reset() async {
    _stopTimer();
    if (state.isRecording || state.isCountingDown) {
      try {
        await _stopUseCase.execute();
      } catch (_) {
        // Ignore errors during reset
      }
    }
    state = const RecordingState();
  }
}

final recordingNotifierProvider =
    NotifierProvider<RecordingNotifier, RecordingState>(RecordingNotifier.new);

/// State for the selected call
class SelectedCallIdNotifier extends Notifier<String> {
  @override
  String build() =>
      ReferenceDatabase.calls.isNotEmpty ? ReferenceDatabase.calls.first.id : 'unknown';

  void setCallId(String id) {
    state = id;
  }
}

final selectedCallIdProvider =
    NotifierProvider<SelectedCallIdNotifier, String>(SelectedCallIdNotifier.new);

/// Stream of amplitude changes for visualization
final amplitudeStreamProvider = StreamProvider<double>((ref) {
  final recorder = ref.watch(audioRecorderServiceProvider);
  return recorder.onAmplitudeChanged;
});
