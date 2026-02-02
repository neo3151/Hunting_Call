import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import '../domain/audio_recorder_service.dart';

class RealAudioRecorderService implements AudioRecorderService {
  final AudioRecorder _recorder = AudioRecorder();
  final _amplitudeController = StreamController<double>.broadcast();
  StreamSubscription? _amplitudeSubscription;
  bool _isRecorderInit = false;
  String? _lastError;
  String? _currentPath;

  @override
  String? get lastError => _lastError;

  @override
  bool get isRecording => _isRecorderInit; // In 'record' plugin, we check via state later but this is for UI toggle

  @override
  Stream<double> get onAmplitudeChanged => _amplitudeController.stream;

  @override
  Future<void> init() async {
    if (_isRecorderInit) return;
    _lastError = null;
    
    try {
      final hasPermission = await _recorder.hasPermission();
      if (!hasPermission) {
        _lastError = "Microphone permission denied";
        debugPrint(_lastError);
        return;
      }
      _isRecorderInit = true;
      debugPrint("Real Recorder: Initialized (record package)");
    } catch (e) {
      _lastError = "Init Error: $e";
      debugPrint(_lastError);
    }
  }

  @override
  Future<bool> startRecorder(String path) async {
    _lastError = null;
    if (!_isRecorderInit) await init();
    if (!_isRecorderInit) return false;

    try {
      if (await _recorder.isRecording()) {
        await _recorder.stop();
      }

      final tempDir = await getTemporaryDirectory();
      final filePath = '${tempDir.path}/hunting_call_${DateTime.now().millisecondsSinceEpoch}.wav';
      _currentPath = filePath;

      const config = RecordConfig(
        encoder: AudioEncoder.wav,
        sampleRate: 44100,
        bitRate: 128000,
        numChannels: 1,
      );

      await _recorder.start(config, path: filePath);

      _amplitudeSubscription = _recorder.onAmplitudeChanged(const Duration(milliseconds: 100)).listen((amp) {
        // amp.current is in dB, usually from -160 to 0
        double normalized = (amp.current + 160) / 160.0;
        if (normalized < 0) normalized = 0;
        if (normalized > 1) normalized = 1;
        _amplitudeController.add(normalized);
      });
      
      debugPrint("Real Recorder: Started recording to $filePath");
      return true;
    } catch (e) {
      _lastError = "Start Error: $e";
      debugPrint(_lastError);
      return false;
    }
  }

  @override
  Future<String?> stopRecorder() async {
    try {
      final path = await _recorder.stop();
      _amplitudeSubscription?.cancel();
      _amplitudeController.add(0.0);
      debugPrint("Real Recorder: Stopped. Path: $path");
      return path ?? _currentPath;
    } catch (e) {
      _lastError = "Stop Error: $e";
      debugPrint(_lastError);
      return null;
    }
  }

  @override
  void dispose() {
    _recorder.dispose();
    _amplitudeSubscription?.cancel();
    _amplitudeController.close();
  }
}

