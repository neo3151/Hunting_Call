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
  String? _lastError;

  @override
  String? get lastError => _lastError;
  
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
    _lastError = null;
    
    // Linux: No init needed for 'arecord' command
    if (Platform.isLinux) {
       _isRecorderInit = true;
       return;
    }

    try {
      if (Platform.isAndroid || Platform.isIOS) {
         final status = await Permission.microphone.request();
         if (status != PermissionStatus.granted) {
            throw Exception('Microphone permission denied');
         }
      }
      
      debugPrint("Real Recorder: Opening recorder session...");
      await _recorder.openRecorder();
      _isRecorderInit = true;
      await _recorder.setSubscriptionDuration(const Duration(milliseconds: 100));
      debugPrint("Real Recorder: Initialized");
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
      final tempDir = await getTemporaryDirectory();
      final filePath = '${tempDir.path}/hunting_call_${DateTime.now().millisecondsSinceEpoch}.wav';

      if (Platform.isLinux) {
        _linuxRecordingPath = filePath;
        _linuxRecorderProcess = await Process.start('arecord', [
          '-f', 'S16_LE',
          '-r', '44100',
          '-c', '1',
          '-t', 'wav',
          filePath
        ]);
        
        _linuxVisualizerTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
           double noise = (DateTime.now().millisecond % 100) / 200.0;
           _amplitudeController.add(0.3 + noise); 
        });
        
        return true;
      }

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

