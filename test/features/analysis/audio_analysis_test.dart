import 'package:flutter_test/flutter_test.dart';
import 'package:outcall/features/analysis/domain/audio_analysis_model.dart';

void main() {
  group('AudioAnalysis Model', () {
    test('simple factory creates valid analysis with all fields populated', () {
      final analysis = AudioAnalysis.simple(
        frequencyHz: 440.0,
        durationSec: 2.5,
        volume: 0.7,
      );

      expect(analysis.dominantFrequencyHz, 440.0);
      expect(analysis.averageFrequencyHz, 440.0);
      expect(analysis.totalDurationSec, 2.5);
      expect(analysis.averageVolume, 0.7);
      expect(analysis.peakVolume, closeTo(1.05, 0.01));
      expect(analysis.waveform.length, 100);
    });

    test('simple factory uses default volume', () {
      final analysis = AudioAnalysis.simple(
        frequencyHz: 880.0,
        durationSec: 1.0,
      );

      expect(analysis.averageVolume, 0.5);
      expect(analysis.peakVolume, 0.75);
    });

    test('all metric fields are within valid ranges', () {
      final analysis = AudioAnalysis.simple(
        frequencyHz: 300.0,
        durationSec: 3.0,
      );

      // 0-100 range metrics
      expect(analysis.pitchStability, inInclusiveRange(0, 100));
      expect(analysis.volumeConsistency, inInclusiveRange(0, 100));
      expect(analysis.toneClarity, inInclusiveRange(0, 100));
      expect(analysis.harmonicRichness, inInclusiveRange(0, 100));
      expect(analysis.brightness, inInclusiveRange(0, 100));
      expect(analysis.warmth, inInclusiveRange(0, 100));
      expect(analysis.nasality, inInclusiveRange(0, 100));
      expect(analysis.callQualityScore, inInclusiveRange(0, 100));
      expect(analysis.noiseLevel, inInclusiveRange(0, 100));
      expect(analysis.rhythmRegularity, inInclusiveRange(0, 100));

      // Duration consistency
      expect(analysis.activeDurationSec + analysis.silenceDurationSec,
          closeTo(analysis.totalDurationSec, 0.001));
    });

    test('JSON round-trip preserves all fields', () {
      final original = AudioAnalysis.simple(
        frequencyHz: 550.0,
        durationSec: 2.0,
        volume: 0.6,
      );

      final json = original.toJson();
      final restored = AudioAnalysis.fromJson(json);

      expect(restored.dominantFrequencyHz, original.dominantFrequencyHz);
      expect(restored.averageFrequencyHz, original.averageFrequencyHz);
      expect(restored.totalDurationSec, original.totalDurationSec);
      expect(restored.averageVolume, original.averageVolume);
      expect(restored.peakVolume, original.peakVolume);
      expect(restored.pitchStability, original.pitchStability);
      expect(restored.toneClarity, original.toneClarity);
      expect(restored.harmonicRichness, original.harmonicRichness);
      expect(restored.brightness, original.brightness);
      expect(restored.warmth, original.warmth);
      expect(restored.nasality, original.nasality);
      expect(restored.callQualityScore, original.callQualityScore);
      expect(restored.noiseLevel, original.noiseLevel);
      expect(restored.waveform.length, original.waveform.length);
      expect(restored.isPulsedCall, original.isPulsedCall);
    });

    test('frequency peaks list contains dominant frequency', () {
      final analysis = AudioAnalysis.simple(
        frequencyHz: 1200.0,
        durationSec: 1.5,
      );

      expect(analysis.frequencyPeaks, contains(1200.0));
    });

    test('waveform values are normalized between 0 and 1', () {
      final analysis = AudioAnalysis.simple(
        frequencyHz: 440.0,
        durationSec: 2.0,
      );

      for (final value in analysis.waveform) {
        expect(value, inInclusiveRange(0, 1));
      }
    });
  });

  group('AnalysisSummary', () {
    test('can be constructed with all required fields', () {
      final summary = AnalysisSummary(
        category: 'Pitch',
        metric: 'Accuracy',
        value: 85.0,
        unit: '%',
        description: 'Good pitch accuracy',
        rating: AnalysisRating.good,
      );

      expect(summary.category, 'Pitch');
      expect(summary.metric, 'Accuracy');
      expect(summary.value, 85.0);
      expect(summary.rating, AnalysisRating.good);
    });
  });

  group('AnalysisRating', () {
    test('has all 4 rating levels', () {
      expect(AnalysisRating.values.length, 4);
      expect(AnalysisRating.values, containsAll([
        AnalysisRating.excellent,
        AnalysisRating.good,
        AnalysisRating.fair,
        AnalysisRating.poor,
      ]));
    });
  });
}
