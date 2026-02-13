import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hunting_calls_perfection/di_providers.dart';
import '../../domain/providers.dart';
import '../../domain/use_cases/start_recording_use_case.dart';
import '../../domain/use_cases/stop_recording_use_case.dart';
import '../../domain/failures/recording_failure.dart';

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

  /// Start recording with countdown
  Future<void> startRecordingWithCountdown() async {
    if (state.isRecording || state.isCountingDown) return;

    state = state.copyWith(status: RecordingStatus.countdown, clearFailure: true);

    final result = await _startUseCase.execute(
      outputPath: 'temp_path', // TODO: Generate proper path from file service
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
        state = state.copyWith(
          status: RecordingStatus.error,
          failure: failure,
          clearCountdown: true,
        );
      },
      // Success
      (audioPath) {
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
      state = state.copyWith(recordDuration: state.recordDuration + 1);
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
        state = state.copyWith(
          status: RecordingStatus.error,
          failure: failure,
        );
        return null;
      },
      // Success
      (audioPath) {
        state = state.copyWith(
          status: RecordingStatus.idle,
          audioPath: audioPath,
        );
        return audioPath;
      },
    );
  }

  /// Reset state
  void reset() {
    _stopTimer();
    state = const RecordingState();
  }
}

final recordingNotifierProvider = NotifierProvider<RecordingNotifier, RecordingState>(() {
  return RecordingNotifier();
});

/// State for the selected call
final selectedCallIdProvider = StateProvider<String>((ref) {
  return "goose_long_distance_contact"; // Default or first call ID
});

/// Stream of amplitude changes for visualization
final amplitudeStreamProvider = StreamProvider<double>((ref) {
  final recorder = ref.watch(audioRecorderServiceProvider);
  return recorder.onAmplitudeChanged;
});
