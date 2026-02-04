import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
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
  static const Duration _osStreamReleaseDelay = Duration(milliseconds: 150);
  
  /// Delay after stopping to allow the OS to finish writing the file.
  static const Duration _fileWriteCompleteDelay = Duration(milliseconds: 150);
  
  /// Interval for amplitude sampling during recording.
  static const Duration _amplitudeSampleInterval = Duration(milliseconds: 50);
  
  /// Standard sample rate for audio recording (CD quality).
  static const int _sampleRate = 44100;
  
  /// Bit rate for audio encoding.
  static const int _bitRate = 128000;
  
  // ============ INSTANCE VARIABLES ============
  
  AudioRecorder? _recorder;
  final _amplitudeController = StreamController<double>.broadcast();
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
    _lastError = null;
    try {
      final tempRecorder = AudioRecorder();
      final hasPermission = await tempRecorder.hasPermission();
      await tempRecorder.dispose();
      
      if (!hasPermission) {
        _lastError = "Microphone permission denied";
        return;
      }
      _isInitialized = true;
    } catch (e) {
      _lastError = "Init Error: $e";
    }
  }

  @override
  Future<bool> startRecorder(String path) async {
    _lastError = null;
    
    // 1. Full cleanup of any previous session
    await _cleanup();
    
    if (!_isInitialized) await init();
    if (!_isInitialized) return false;

    // 2. Allow OS to release the audio stream from previous recording
    await Future.delayed(_osStreamReleaseDelay);

    try {
      _recorder = AudioRecorder();

      String filePath;
      if (kIsWeb) {
        filePath = 'recording.wav'; 
      } else {
        final tempDir = await getTemporaryDirectory();
        filePath = '${tempDir.path}/hunting_call_${DateTime.now().millisecondsSinceEpoch}.wav';
      }
      _currentPath = filePath;

      const config = RecordConfig(
        encoder: AudioEncoder.wav,
        sampleRate: _sampleRate,
        bitRate: _bitRate,
        numChannels: 1,
      );

      await _recorder!.start(config, path: filePath);

      _amplitudeSubscription = _recorder!.onAmplitudeChanged(_amplitudeSampleInterval).listen((amp) {
        double normalized = (amp.current - _amplitudeDbMin) / (-_amplitudeDbMin);
        normalized = normalized.clamp(0.0, 1.0);
        _amplitudeController.add(normalized);
      });
      
      return true;
    } catch (e) {
      _lastError = "Start Error: $e";
      await _cleanup();
      return false;
    }
  }

  @override
  Future<String?> stopRecorder() async {
    try {
      if (_recorder == null) return _currentPath;
      
      final path = await _recorder!.stop();
      
      // 3. Give the OS time to finish writing the file handle
      await Future.delayed(_fileWriteCompleteDelay);
      
      return path ?? _currentPath;
    } catch (e) {
      _lastError = "Stop Error: $e";
      return null;
    } finally {
      // 4. Force disposal immediately after stopping
      await _cleanup();
    }
  }

  Future<void> _cleanup() async {
    _amplitudeSubscription?.cancel();
    _amplitudeSubscription = null;
    _amplitudeController.add(0.0);
    
    if (_recorder != null) {
      try {
        if (await _recorder!.isRecording()) {
          await _recorder!.stop();
        }
      } catch (_) {}
      await _recorder!.dispose();
      _recorder = null;
    }
  }

  @override
  void dispose() {
    _cleanup();
    _amplitudeController.close();
  }
}


