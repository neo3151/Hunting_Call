import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../domain/audio_recorder_service.dart';

class RealAudioRecorderService implements AudioRecorderService {
  // ============ CONFIGURATION CONSTANTS ============
  
  /// Amplitude offset for normalization. The `record` package reports amplitude
  /// in decibels from approximately -160 (silence) to 0 (maximum). We normalize
  /// this to a 0.0-1.0 range for the visualizer.
  static const double _amplitudeDbMin = -160.0;
  
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
      debugPrint("RealAudioRecorder: Initializing...");
      final tempRecorder = AudioRecorder();
      final hasPermission = await tempRecorder.hasPermission();
      debugPrint("RealAudioRecorder: Has permission: $hasPermission");
      await tempRecorder.dispose();
      
      if (!hasPermission) {
        _lastError = "Microphone permission denied. Please grant access in your system settings.";
        debugPrint("RealAudioRecorder: ERROR - $_lastError");
        return;
      }
      _isInitialized = true;
      debugPrint("RealAudioRecorder: Initialized successfully");
    } catch (e) {
      _lastError = "Initialization Error: $e";
      debugPrint("RealAudioRecorder: ERROR - $_lastError");
    }
  }

  @override
  Future<bool> startRecorder(String path) async {
    _lastError = null;
    
    debugPrint("RealAudioRecorder: startRecorder called");
    // 1. Full cleanup of any previous session
    await _cleanup();
    
    // Ensure we are initialized
    if (!_isInitialized) {
      debugPrint("RealAudioRecorder: Not initialized, calling init()");
      await init();
      if (!_isInitialized) {
        debugPrint("RealAudioRecorder: Still not initialized after init(), aborting");
        return false;
      }
    }

    // 2. Allow OS to release the audio stream from previous recording
    // Stability delay for OS audio driver context switch
    await Future.delayed(_osStreamReleaseDelay);

    try {
      _recorder = AudioRecorder();

      String filePath;
      if (kIsWeb) {
        filePath = 'recording_${DateTime.now().millisecondsSinceEpoch}.wav'; 
      } else {
        final tempDir = await getTemporaryDirectory();
        final fileName = 'hunting_call_${DateTime.now().millisecondsSinceEpoch}.wav';
        filePath = p.join(tempDir.path, fileName);
        
        // Ensure parent directory exists (needed on some platforms)
        final dir = Directory(tempDir.path);
        if (!await dir.exists()) {
          await dir.create(recursive: true);
        }
      }
      _currentPath = filePath;
      debugPrint("RealAudioRecorder: Recording to: $filePath");

      const config = RecordConfig(
        encoder: AudioEncoder.wav,
        sampleRate: _sampleRate,
        bitRate: _bitRate,
        numChannels: 1,
      );

      // Start recording
      await _recorder!.start(config, path: filePath);
      debugPrint("RealAudioRecorder: Recording started successfully");

      // Listen for amplitude changes for visualizer
      _amplitudeSubscription = _recorder!.onAmplitudeChanged(_amplitudeSampleInterval).listen(
        (amp) {
          // Normalize -160dB to 0dB range to 0.0 to 1.0
          double normalized = (amp.current - _amplitudeDbMin) / (-_amplitudeDbMin);
          normalized = normalized.clamp(0.0, 1.0);
          _amplitudeController.add(normalized);
        },
        onError: (e) => debugPrint("RealAudioRecorder: Amplitude stream error: $e"),
      );
      
      return true;
    } catch (e) {
      _lastError = "Failed to start recording: $e";
      debugPrint("RealAudioRecorder: ERROR - $_lastError");
      await _cleanup();
      return false;
    }
  }

  @override
  Future<String?> stopRecorder() async {
    try {
      debugPrint("RealAudioRecorder: stopRecorder called");
      if (_recorder == null) {
        debugPrint("RealAudioRecorder: No active recorder, returning cached path");
        return _currentPath;
      }
      
      final savedPath = await _recorder!.stop();
      debugPrint("RealAudioRecorder: Stopped, path: $savedPath");
      
      // Crucial: Give the OS a moment to release the file handle
      await Future.delayed(_fileWriteCompleteDelay);
      
      return savedPath ?? _currentPath;
    } catch (e) {
      _lastError = "Failed to stop recording: $e";
      debugPrint("RealAudioRecorder: ERROR - $_lastError");
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
      debugPrint("Cleanup Error: $e");
    }
  }

  @override
  void dispose() {
    _cleanup();
    _amplitudeController.close();
  }
}


