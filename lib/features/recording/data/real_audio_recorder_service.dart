import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import '../domain/audio_recorder_service.dart';

class RealAudioRecorderService implements AudioRecorderService {
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
      // We create a temporary recorder just to check permission
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

    // 2. Tiny delay to allow Windows to release the audio stream
    await Future.delayed(const Duration(milliseconds: 150));

    try {
      _recorder = AudioRecorder();

      String filePath;
      if (kIsWeb) {
        // On web, we don't need a file path; the plugin handles it in-memory
        filePath = 'recording.wav'; 
      } else {
        final tempDir = await getTemporaryDirectory();
        filePath = '${tempDir.path}/hunting_call_${DateTime.now().millisecondsSinceEpoch}.wav';
      }
      _currentPath = filePath;

      const config = RecordConfig(
        encoder: AudioEncoder.wav,
        sampleRate: 44100,
        bitRate: 128000,
        numChannels: 1,
      );

      await _recorder!.start(config, path: filePath);

      _amplitudeSubscription = _recorder!.onAmplitudeChanged(const Duration(milliseconds: 50)).listen((amp) {
        double normalized = (amp.current + 160) / 160.0;
        if (normalized < 0) normalized = 0;
        if (normalized > 1) normalized = 1;
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
      await Future.delayed(const Duration(milliseconds: 150));
      
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


