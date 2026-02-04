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

  const RecordingState({
    this.status = RecordingStatus.idle,
    this.audioPath,
    this.error,
    this.amplitudes = const [],
  });

  bool get isRecording => status == RecordingStatus.recording;

  RecordingState copyWith({
    RecordingStatus? status,
    String? audioPath,
    String? error,
    List<double>? amplitudes,
  }) {
    return RecordingState(
      status: status ?? this.status,
      audioPath: audioPath ?? this.audioPath,
      error: error,
      amplitudes: amplitudes ?? this.amplitudes,
    );
  }
}

/// Notifier for recording operations
class RecordingNotifier extends Notifier<RecordingState> {
  @override
  RecordingState build() {
    return const RecordingState();
  }

  AudioRecorderService get _recorder => ref.read(audioRecorderServiceProvider);

  /// Initialize the recorder
  Future<void> initialize() async {
    state = state.copyWith(status: RecordingStatus.initializing, error: null);
    try {
      await _recorder.init();
      state = state.copyWith(status: RecordingStatus.idle);
    } catch (e) {
      state = state.copyWith(status: RecordingStatus.error, error: e.toString());
    }
  }

  /// Start recording
  Future<bool> startRecording() async {
    state = state.copyWith(status: RecordingStatus.initializing, error: null, amplitudes: []);
    try {
      final success = await _recorder.startRecorder('temp_path');
      if (success) {
        state = state.copyWith(status: RecordingStatus.recording);
        return true;
      } else {
        state = state.copyWith(
          status: RecordingStatus.error,
          error: _recorder.lastError ?? 'Failed to start recording',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(status: RecordingStatus.error, error: e.toString());
      return false;
    }
  }

  /// Stop recording
  Future<String?> stopRecording() async {
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
    final newAmplitudes = [...state.amplitudes, amplitude];
    if (newAmplitudes.length > 50) {
      newAmplitudes.removeAt(0);
    }
    state = state.copyWith(amplitudes: newAmplitudes);
  }

  /// Reset state
  void reset() {
    state = const RecordingState();
  }
}

final recordingNotifierProvider = NotifierProvider<RecordingNotifier, RecordingState>(() {
  return RecordingNotifier();
});

/// Stream of amplitude changes for visualization
final amplitudeStreamProvider = StreamProvider<double>((ref) {
  final recorder = ref.watch(audioRecorderServiceProvider);
  return recorder.onAmplitudeChanged;
});
