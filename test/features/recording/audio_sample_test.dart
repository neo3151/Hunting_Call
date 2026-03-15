import 'package:flutter_test/flutter_test.dart';
import 'package:outcall/features/recording/domain/audio_sample.dart';

void main() {
  group('AudioSample', () {
    test('stores time and amplitude', () {
      const sample = AudioSample(1.5, 0.75);
      expect(sample.timeSec, 1.5);
      expect(sample.amplitude, 0.75);
    });

    test('handles zero values', () {
      const sample = AudioSample(0.0, 0.0);
      expect(sample.timeSec, 0.0);
      expect(sample.amplitude, 0.0);
    });

    test('handles negative amplitude', () {
      const sample = AudioSample(0.5, -0.9);
      expect(sample.amplitude, -0.9);
    });

    test('handles very small time increments', () {
      const sample = AudioSample(0.00001, 0.5);
      expect(sample.timeSec, closeTo(0.00001, 1e-10));
    });
  });
}
