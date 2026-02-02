import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import '../domain/audio_recorder_service.dart';

class RealAudioRecorderService implements AudioRecorderService {
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  final _amplitudeController = StreamController<double>.broadcast();
  StreamSubscription? _recorderSubscription;
  bool _isRecorderInit = false;
  
  // Linux Native Recording
  Process? _linuxRecorderProcess;
  Timer? _linuxVisualizerTimer;
  String? _linuxRecordingPath;

  @override
  bool get isRecording => Platform.isLinux ? (_linuxRecorderProcess != null) : _recorder.isRecording;

  @override
  Stream<double> get onAmplitudeChanged => _amplitudeController.stream;

  @override
  Future<void> init() async {
    if (_isRecorderInit) return;
    
    // Linux: No init needed for 'arecord' command, just checking permissions theoretically
    if (Platform.isLinux) {
       _isRecorderInit = true; // We assume arecord works if the OS works
       return;
    }

    // Mobile/Other: Init Flutter Sound
    try {
      if (!Platform.isLinux) {
         final status = await Permission.microphone.request();
         if (status != PermissionStatus.granted) {
            throw Exception('Permission denied');
         }
      }
      await _recorder.openRecorder();
      _isRecorderInit = true;
      await _recorder.setSubscriptionDuration(const Duration(milliseconds: 100));
      debugPrint("Real Recorder: Initialized");
    } catch (e) {
      debugPrint("Real Recorder Init Error: $e");
    }
  }

  @override
  Future<bool> startRecorder(String path) async {
    if (!_isRecorderInit) await init();

    try {
      final tempDir = await getTemporaryDirectory();
      final filePath = '${tempDir.path}/hunting_call_${DateTime.now().millisecondsSinceEpoch}.wav';

      // --- LINUX NATIVE STRATEGY ---
      if (Platform.isLinux) {
        // Use 'arecord' system command to bypass plugin issues
        // -f S16_LE: Signed 16-bit Little Endian
        // -r 44100: 44.1kHz
        // -c 1: Mono
        // -t wav: WAV format
        _linuxRecordingPath = filePath;
        debugPrint("Starting arecord to: $filePath");
        
        _linuxRecorderProcess = await Process.start('arecord', [
          '-f', 'S16_LE',
          '-r', '44100',
          '-c', '1',
          '-t', 'wav',
          filePath
        ]);
        
        // Simulate visualizer since we can't easily parse stdout stream in real-time without blocking
        _linuxVisualizerTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
           // Create a "breathing" effect + random noise to look active
           double noise = (DateTime.now().millisecond % 100) / 200.0;
           _amplitudeController.add(0.3 + noise); 
        });
        
        return true;
      }

      // --- MOBILE / STANDARD STRATEGY ---
      if (!_isRecorderInit) return false;

      await _recorder.startRecorder(
        toFile: filePath,
        codec: Codec.pcm16WAV, 
      );

      _recorderSubscription = _recorder.onProgress!.listen((e) {
        double amp = (e.decibels ?? 0) / 120.0;
        if (amp < 0) amp = 0;
        if (amp > 1) amp = 1;
        _amplitudeController.add(amp);
      });
      
      debugPrint("Real Recorder: Started recording to $filePath");
      return true;
    } catch (e) {
      debugPrint("Real Recorder Start Error: $e");
      return false;
    }
  }

  @override
  Future<String?> stopRecorder() async {
    try {
      // --- LINUX NATIVE STRATEGY ---
      if (Platform.isLinux) {
        _linuxRecorderProcess?.kill();
        _linuxRecorderProcess = null;
        _linuxVisualizerTimer?.cancel();
        _amplitudeController.add(0.0);
        debugPrint("Real Recorder (Linux): Stopped. Saved at $_linuxRecordingPath");
        return _linuxRecordingPath;
      }

      // --- MOBILE STRATEGY ---
      final path = await _recorder.stopRecorder();
      _recorderSubscription?.cancel();
      _amplitudeController.add(0.0);
      return path;
    } catch (e) {
      debugPrint("Real Recorder Stop Error: $e");
      return null;
    }
  }

  @override
  void dispose() {
    if (Platform.isLinux) {
       _linuxRecorderProcess?.kill();
       _linuxVisualizerTimer?.cancel();
    }
    _recorder.closeRecorder();
    _recorderSubscription?.cancel();
    _amplitudeController.close();
  }
}

