import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:outcall/core/utils/app_logger.dart';
import 'dart:math' as math;

class BioacousticScorer {
  static Interpreter? _interpreter;
  static List<String>? _labels;

  static const int sampleRate = 48000;
  static const int durationSec = 3;
  static const int inputSize = sampleRate * durationSec; // 144,000 PCM floats

  static Future<void> loadModel() async {
    try {
      if (_interpreter != null) return;
      _interpreter = await Interpreter.fromAsset('assets/models/birdnet_lite.tflite');
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
    if (_interpreter == null || _labels == null) return []; // Fallback if load fails

    try {
      // 1. Prepare raw audio input [1, 144000]
      // BirdNET handles the mel-spectrogram conversion internally via the TFLite graph.
      // We just need to zero-pad or truncate to exactly 3 seconds at 48kHz.
      List<double> chunk = List.filled(inputSize, 0.0);
      final int len = math.min(audioBuffer.length, inputSize);
      for (int i = 0; i < len; i++) {
        chunk[i] = audioBuffer[i];
      }
      final input0 = [chunk]; // Shape: [1, 144000]

      // 2. Prepare metadata input [1, 6] (lat, lon, week, mask_lat, mask_lon, mask_week)
      // We pass the default (-1) to run a global classification unconditionally.
      final input1 = [
        [-1.0, -1.0, -1.0, 0.0, 0.0, 0.0]
      ];

      // 3. Prepare output tensor [1, numClasses]
      var output = List.filled(1, List.filled(_labels!.length, 0.0));

      // Run inference bridging both inputs
      _interpreter!.runForMultipleInputs([input0, input1], {0: output});

      final probs = output[0];
      final results = <MapEntry<String, double>>[];

      // Map indices back to labels
      for (int i = 0; i < probs.length; i++) {
        double sigProb = _customSigmoid(probs[i]); // BirdNET requires a custom sigmoid scaler
        if (sigProb > 0.05) {
          // Confidence threshold filter
          results.add(MapEntry(
              _labels![i].split('_').last, sigProb * 100)); // Remove scientific prefix if present
        }
      }

      // Sort by highest confidence
      results.sort((a, b) => b.value.compareTo(a.value));
      return results.take(3).toList();
    } catch (e, stack) {
      AppLogger.e('BioacousticScorer identification failed', e, stack);
      return [];
    }
  }

  /// Softmax/Sigmoid custom conversion to align with BirdNET's expected probability scoring
  static double _customSigmoid(double x, {double sensitivity = 1.0}) {
    return 1 / (1.0 + math.exp(-sensitivity * x));
  }
}
