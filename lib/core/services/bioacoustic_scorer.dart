import 'dart:io';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:outcall/core/utils/app_logger.dart';
import 'dart:math' as math;

class BioacousticScorer {
  static Interpreter? _interpreter;
  static List<String>? _labels;

  static const int sampleRate = 48000;
  static const int durationSec = 3;
  static const int inputSize = sampleRate * durationSec; // 144,000 PCM floats

  static const String _modelFileName = 'birdnet_lite.tflite';
  static const String _modelStorageUrl =
      'https://firebasestorage.googleapis.com/v0/b/hunting-call-perfection.firebasestorage.app/o/ai-models%2Fbirdnet_lite.tflite?alt=media';

  static Future<String> _getLocalModelPath() async {
    final dir = await getApplicationDocumentsDirectory();
    return '${dir.path}/$_modelFileName';
  }

  static Future<void> _downloadModelIfNeeded() async {
    final localPath = await _getLocalModelPath();
    final file = File(localPath);
    if (await file.exists() && await file.length() > 1000000) return;

    AppLogger.d('BioacousticScorer: Downloading model from Firebase Storage...');
    try {
      final response = await http.get(Uri.parse(_modelStorageUrl))
          .timeout(const Duration(minutes: 3));
      if (response.statusCode == 200) {
        await file.writeAsBytes(response.bodyBytes);
        AppLogger.d('BioacousticScorer: Model downloaded (${(response.bodyBytes.length / 1024 / 1024).toStringAsFixed(1)} MB)');
      } else {
        throw Exception('HTTP ${response.statusCode}');
      }
    } catch (e) {
      AppLogger.e('BioacousticScorer: Model download failed', e);
      rethrow;
    }
  }

  static Future<void> loadModel() async {
    try {
      if (_interpreter != null) return;

      await _downloadModelIfNeeded();

      final localPath = await _getLocalModelPath();
      _interpreter = Interpreter.fromFile(File(localPath));

      final labelsData = await rootBundle.loadString('assets/models/labels.txt');
      _labels = labelsData.split('\n').where((s) => s.isNotEmpty).toList();
      AppLogger.d('BioacousticScorer: Loaded model and ${_labels!.length} classes.');
    } catch (e) {
      AppLogger.e('BioacousticScorer: Failed to load TFLite model', e);
    }
  }

  /// Returns top-3 predicted animals + confidence percentage
  static Future<List<MapEntry<String, double>>> identify({
    required List<double> audioBuffer,
  }) async {
    if (_interpreter == null || _labels == null) await loadModel();
    if (_interpreter == null || _labels == null) return [];

    try {
      // 1. Prepare raw audio input [1, 144000]
      final chunk = List.filled(inputSize, 0.0);
      final int len = math.min(audioBuffer.length, inputSize);
      for (int i = 0; i < len; i++) {
        chunk[i] = audioBuffer[i];
      }
      final input0 = [chunk];

      // 2. Metadata input [1, 6] — pass -1 for global (location-agnostic) classification
      final input1 = [
        [-1.0, -1.0, -1.0, 0.0, 0.0, 0.0]
      ];

      // 3. Output tensor [1, numClasses]
      final output = List.filled(1, List.filled(_labels!.length, 0.0));

      _interpreter!.runForMultipleInputs([input0, input1], {0: output});

      final probs = output[0];
      final results = <MapEntry<String, double>>[];

      for (int i = 0; i < probs.length; i++) {
        final sigProb = _customSigmoid(probs[i]);
        if (sigProb > 0.05) {
          results.add(MapEntry(
              _labels![i].split('_').last, sigProb * 100));
        }
      }

      results.sort((a, b) => b.value.compareTo(a.value));
      return results.take(3).toList();
    } catch (e, stack) {
      AppLogger.e('BioacousticScorer identification failed', e, stack);
      return [];
    }
  }

  /// Custom sigmoid to align with BirdNET's expected probability scoring
  static double _customSigmoid(double x, {double sensitivity = 1.0}) {
    return 1 / (1.0 + math.exp(-sensitivity * x));
  }
}
