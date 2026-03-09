import 'package:flutter_test/flutter_test.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

void main() {
  test('Inspect BirdNET TFLite Model', () async {
    final interpreter = Interpreter.fromFile('assets/models/birdnet_lite.tflite');

    print('--- INPUT TENSORS ---');
    for (var tensor in interpreter.getInputTensors()) {
      print('Name: ${tensor.name}, Shape: ${tensor.shape}, Type: ${tensor.type}');
    }

    print('--- OUTPUT TENSORS ---');
    for (var tensor in interpreter.getOutputTensors()) {
      print('Name: ${tensor.name}, Shape: ${tensor.shape}, Type: ${tensor.type}');
    }
  });
}
