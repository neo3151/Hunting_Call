import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../domain/audio_recorder_service.dart';

class MockAudioRecorderService implements AudioRecorderService {
  Timer? _timer;
  final _amplitudeController = StreamController<double>.broadcast();
  bool _isRecording = false;

  @override
  bool get isRecording => _isRecording;

  @override
  Stream<double> get onAmplitudeChanged => _amplitudeController.stream;

  @override
  Future<void> init() async {
    // Simulate perm request
    // await Future.delayed(const Duration(milliseconds: 200));
    debugPrint("Mock Recorder: Init");
  }

  @override
  Future<bool> startRecorder(String path) async {
    _isRecording = true;
    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      // Generate fake waveform data (0.0 to 1.0)
       double randomAmp = Random().nextDouble();
       _amplitudeController.add(randomAmp);
    });
    debugPrint("Mock Recorder: Started recording to $path");
    return true;
  }

  @override
  Future<String?> stopRecorder() async {
    _isRecording = false;
    _timer?.cancel();
    _amplitudeController.add(0.0); 
    debugPrint("Mock Recorder: Stopped.");
    return "mock/path/to/audio.aac";
  }

  @override
  void dispose() {
    _timer?.cancel();
    _amplitudeController.close();
  }
}
