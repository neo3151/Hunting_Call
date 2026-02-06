import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import '../features/recording/domain/audio_recorder_service.dart';

/// Provides the AudioRecorderService instance
final audioRecorderServiceProvider = Provider<AudioRecorderService>((ref) {
  return GetIt.I<AudioRecorderService>();
});

/// State for recording session
enum RecordingStatus { idle, initializing, recording, stopping, error }

class RecordingState {
  final RecordingStatus status;
  final String? audioPath;
  final String? error;
  final List<double> amplitudes;
  final int recordDuration;
  final int? countdownValue;

  const RecordingState({
    this.status = RecordingStatus.idle,
    this.audioPath,
    this.error,
    this.amplitudes = const [],
    this.recordDuration = 0,
    this.countdownValue,
  });

  bool get isRecording => status == RecordingStatus.recording;
  bool get isCountingDown => countdownValue != null;

  RecordingState copyWith({
    RecordingStatus? status,
    String? audioPath,
    String? error,
    List<double>? amplitudes,
    int? recordDuration,
    int? countdownValue,
    bool clearError = false,
    bool clearCountdown = false,
  }) {
    return RecordingState(
      status: status ?? this.status,
      audioPath: audioPath ?? this.audioPath,
      error: clearError ? null : (error ?? this.error),
      amplitudes: amplitudes ?? this.amplitudes,
      recordDuration: recordDuration ?? this.recordDuration,
      countdownValue: clearCountdown ? null : (countdownValue ?? this.countdownValue),
    );
  }
}

/// Notifier for recording operations
class RecordingNotifier extends Notifier<RecordingState> {
  Timer? _timer;

  @override
  RecordingState build() {
    ref.onDispose(() {
      _timer?.cancel();
    });
    return const RecordingState();
  }

  AudioRecorderService get _recorder => ref.read(audioRecorderServiceProvider);

  /// Initialize the recorder
  Future<void> initialize() async {
    state = state.copyWith(status: RecordingStatus.initializing, clearError: true);
    try {
      await _recorder.init();
      state = state.copyWith(status: RecordingStatus.idle);
    } catch (e) {
      state = state.copyWith(status: RecordingStatus.error, error: e.toString());
    }
  }

  /// Start recording (with optional countdown)
  Future<void> startRecordingWithCountdown() async {
    if (state.isRecording || state.isCountingDown) return;

    // Start countdown
    for (int i = 3; i > 0; i--) {
      state = state.copyWith(countdownValue: i);
      await Future.delayed(const Duration(seconds: 1));
    }
    state = state.copyWith(clearCountdown: true);

    // Start recording
    state = state.copyWith(status: RecordingStatus.initializing, clearError: true, amplitudes: [], recordDuration: 0);
    try {
      final success = await _recorder.startRecorder('temp_path');
      if (success) {
        state = state.copyWith(status: RecordingStatus.recording);
        _startTimer();
      } else {
        state = state.copyWith(
          status: RecordingStatus.error,
          error: _recorder.lastError ?? 'Failed to start recording',
        );
      }
    } catch (e) {
      state = state.copyWith(status: RecordingStatus.error, error: e.toString());
    }
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
    try {
      final path = await _recorder.stopRecorder();
      state = state.copyWith(status: RecordingStatus.idle, audioPath: path);
      return path;
    } catch (e) {
      state = state.copyWith(status: RecordingStatus.error, error: e.toString());
      return null;
    }
  }

  /// Update amplitudes for visualization
  void updateAmplitudes(double amplitude) {
    if (!state.isRecording) return;
    final newAmplitudes = [...state.amplitudes, amplitude];
    if (newAmplitudes.length > 50) {
      newAmplitudes.removeAt(0);
    }
    state = state.copyWith(amplitudes: newAmplitudes);
  }

  /// Reset state
  void reset() {
    _stopTimer();
    state = const RecordingState();
  }

  /// Reset amplitudes only
  void resetAmplitudes() {
    state = state.copyWith(amplitudes: []);
  }
}

final recordingNotifierProvider = NotifierProvider<RecordingNotifier, RecordingState>(() {
  return RecordingNotifier();
});

/// State for the selected call
final selectedCallIdProvider = StateProvider<String>((ref) {
  // We'll import ReferenceDatabase if needed, but for now just a string
  return "goose_long_distance_contact"; // Default or first call ID
});

/// Stream of amplitude changes for visualization
final amplitudeStreamProvider = StreamProvider<double>((ref) {
  final recorder = ref.watch(audioRecorderServiceProvider);
  return recorder.onAmplitudeChanged;
});
