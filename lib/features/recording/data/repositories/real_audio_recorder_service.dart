import 'dart:async';
import 'dart:io';

import 'package:record/record.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../../domain/audio_recorder_service.dart';
import 'package:hunting_calls_perfection/core/utils/app_logger.dart';

class RealAudioRecorderService implements AudioRecorderService {
  // ============ CONFIGURATION CONSTANTS ============
  
  /// Amplitude noise floor for normalization. The `record` package reports amplitude
  /// in decibels where 0 is maximum and negative values are quieter. We use -55dB
  /// as the floor so ambient noise (~-60dB) reads as zero and the visualizer only
  /// responds to intentional voice input. Values between -55dB and 0dB map to 0.0–1.0.
  static const double _amplitudeDbMin = -55.0;
  
  /// Delay after cleanup to allow the OS to release audio stream handles.
  /// This is a workaround for Windows which doesn't release handles immediately.
  /// Increase if recording fails on slower machines.
  static const Duration _osStreamReleaseDelay = Duration(milliseconds: 200);
  
  /// Delay after stopping to allow the OS to finish writing the file.
  static const Duration _fileWriteCompleteDelay = Duration(milliseconds: 200);
  
  /// Interval for amplitude sampling during recording.
  static const Duration _amplitudeSampleInterval = Duration(milliseconds: 50);
  
  /// Standard sample rate for audio recording (CD quality).
  static const int _sampleRate = 44100;
  
  /// Bit rate for audio encoding.
  static const int _bitRate = 128000;
  
  // ============ INSTANCE VARIABLES ============
  
  AudioRecorder? _recorder;
  final StreamController<double> _amplitudeController = StreamController<double>.broadcast();
  StreamSubscription? _amplitudeSubscription;
  bool _isInitialized = false;
  String? _lastError;
  String? _currentPath;

  @override
  String? get lastError => _lastError;

  @override
  bool get isRecording => _recorder != null;

  @override
  Stream<double> get onAmplitudeChanged => _amplitudeController.stream;

  @override
  Future<void> init() async {
    if (_isInitialized) return;
    _lastError = null;
    try {
      AppLogger.d('RealAudioRecorder: Initializing...');
      final tempRecorder = AudioRecorder();
      final hasPermission = await tempRecorder.hasPermission();
      AppLogger.d('RealAudioRecorder: Has permission: $hasPermission');
      await tempRecorder.dispose();
      
      if (!hasPermission) {
        _lastError = 'Microphone permission denied. Please grant access in your system settings.';
        AppLogger.d('RealAudioRecorder: ERROR - $_lastError');
        return;
      }
      _isInitialized = true;
      AppLogger.d('RealAudioRecorder: Initialized successfully');
    } catch (e) {
      _lastError = 'Initialization Error: $e';
      AppLogger.d('RealAudioRecorder: ERROR - $_lastError');
    }
  }

  @override
  Future<bool> startRecorder(String path) async {
    _lastError = null;
    
    AppLogger.d('RealAudioRecorder: startRecorder called');
    // 1. Full cleanup of any previous session
    await _cleanup();
    
    // Ensure we are initialized
    if (!_isInitialized) {
      AppLogger.d('RealAudioRecorder: Not initialized, calling init()');
      await init();
      if (!_isInitialized) {
        AppLogger.d('RealAudioRecorder: Still not initialized after init(), aborting');
        return false;
      }
    }

    // 2. Allow OS to release the audio stream from previous recording
    // Stability delay for OS audio driver context switch
    await Future.delayed(_osStreamReleaseDelay);

    try {
      _recorder = AudioRecorder();

      _currentPath = path;
      AppLogger.d('RealAudioRecorder: Recording to: $path');

      const config = RecordConfig(
        encoder: AudioEncoder.wav,
        sampleRate: _sampleRate,
        bitRate: _bitRate,
        numChannels: 1,
      );

      // Start recording
      await _recorder!.start(config, path: _currentPath!);
      AppLogger.d('RealAudioRecorder: Recording started successfully');

      // Listen for amplitude changes for visualizer
      _amplitudeSubscription = _recorder!.onAmplitudeChanged(_amplitudeSampleInterval).listen(
        (amp) {
          if (_amplitudeController.isClosed) return;
          // Normalize -160dB to 0dB range to 0.0 to 1.0
          double normalized = (amp.current - _amplitudeDbMin) / (-_amplitudeDbMin);
          normalized = normalized.clamp(0.0, 1.0);
          _amplitudeController.add(normalized);
        },
        onError: (e) => AppLogger.d('RealAudioRecorder: Amplitude stream error: $e'),
      );
      
      return true;
    } catch (e) {
      _lastError = 'Failed to start recording: $e';
      AppLogger.d('RealAudioRecorder: ERROR - $_lastError');
      await _cleanup();
      return false;
    }
  }

  @override
  Future<String?> stopRecorder() async {
    try {
      AppLogger.d('RealAudioRecorder: stopRecorder called');
      if (_recorder == null) {
        AppLogger.d('RealAudioRecorder: No active recorder, returning cached path');
        return _currentPath;
      }
      
      final savedPath = await _recorder!.stop();
      AppLogger.d('RealAudioRecorder: Stopped, path: $savedPath');
      
      // Crucial: Give the OS a moment to release the file handle
      await Future.delayed(_fileWriteCompleteDelay);
      
      return savedPath ?? _currentPath;
    } catch (e) {
      _lastError = 'Failed to stop recording: $e';
      AppLogger.d('RealAudioRecorder: ERROR - $_lastError');
      return _currentPath;
    } finally {
      await _cleanup();
    }
  }

  Future<void> _cleanup() async {
    try {
      await _amplitudeSubscription?.cancel();
      _amplitudeSubscription = null;
      
      if (_recorder != null) {
        if (await _recorder!.isRecording()) {
          await _recorder!.stop();
        }
        await _recorder!.dispose();
        _recorder = null;
      }
    } catch (e) {
      AppLogger.d('Cleanup Error: $e');
    }
  }

  @override
  void dispose() {
    _cleanup();
    _amplitudeController.close();
  }

  @override
  Future<void> cleanupOldFiles() async {
    try {
      AppLogger.d('RealAudioRecorder: Running storage cleanup...');
      final tempDir = await getTemporaryDirectory();
      final dir = Directory(tempDir.path);
      
      if (await dir.exists()) {
        final List<FileSystemEntity> files = await dir.list().toList();
        final now = DateTime.now();
        int deletedCount = 0;

        // Load settings to get cleanup frequency
        final prefs = await SharedPreferences.getInstance();
        final cleanupHours = prefs.getInt('app_settings_autoCleanupHours') ?? 24;

        if (cleanupHours <= 0) {
          AppLogger.d('RealAudioRecorder: Cleanup skipped. User has selected never to delete recordings.');
          return;
        }

        for (final file in files) {
          if (file is File && p.extension(file.path) == '.wav' && p.basename(file.path).startsWith('hunting_call_')) {
            final stat = await file.stat();
            // Delete files older than the specified hours
            if (now.difference(stat.modified).inHours >= cleanupHours) {
              await file.delete();
              deletedCount++;
            }
          }
        }
        AppLogger.d('RealAudioRecorder: Cleanup complete. Deleted $deletedCount old recordings.');
      }
    } catch (e) {
      AppLogger.d('RealAudioRecorder: Cleanup ERROR - $e');
    }
  }
}


