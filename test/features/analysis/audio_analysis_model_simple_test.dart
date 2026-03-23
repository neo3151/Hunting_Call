import 'package:flutter_test/flutter_test.dart';
import 'package:outcall/features/analysis/domain/audio_analysis_model.dart';

void main() {
  group('AudioAnalysis.simple', () {
    test('creates with required fields', () {
      final analysis = AudioAnalysis.simple(
        frequencyHz: 720.0,
        durationSec: 3.5,
      );
      expect(analysis.dominantFrequencyHz, 720.0);
      expect(analysis.averageFrequencyHz, 720.0);
      expect(analysis.totalDurationSec, 3.5);
    });

    test('default volume is 0.5', () {
      final analysis = AudioAnalysis.simple(
        frequencyHz: 500.0,
        durationSec: 2.0,
      );
      expect(analysis.averageVolume, 0.5);
      expect(analysis.peakVolume, 0.75);
    });

    test('custom volume override', () {
      final analysis = AudioAnalysis.simple(
        frequencyHz: 500.0,
        durationSec: 2.0,
        volume: 0.8,
      );
      expect(analysis.averageVolume, 0.8);
      expect(analysis.peakVolume, 1.2);
    });

    test('activeDurationSec is 90% of total', () {
      final analysis = AudioAnalysis.simple(
        frequencyHz: 500.0,
        durationSec: 10.0,
      );
      expect(analysis.activeDurationSec, closeTo(9.0, 0.01));
      expect(analysis.silenceDurationSec, closeTo(1.0, 0.01));
    });

    test('defaults have neutral scoring values', () {
      final analysis = AudioAnalysis.simple(
        frequencyHz: 500.0,
        durationSec: 2.0,
      );
      expect(analysis.pitchStability, 50.0);
      expect(analysis.volumeConsistency, 50.0);
      expect(analysis.toneClarity, 50.0);
      expect(analysis.harmonicRichness, 50.0);
      expect(analysis.brightness, 50.0);
      expect(analysis.warmth, 50.0);
      expect(analysis.nasality, 50.0);
    });

    test('waveform has 100 data points', () {
      final analysis = AudioAnalysis.simple(
        frequencyHz: 500.0,
        durationSec: 2.0,
      );
      expect(analysis.waveform.length, 100);
    });

    test('new dimension fields default to empty/zero', () {
      final analysis = AudioAnalysis.simple(
        frequencyHz: 500.0,
        durationSec: 2.0,
      );
      expect(analysis.pitchContour, isEmpty);
      expect(analysis.onsetTimes, isEmpty);
      expect(analysis.attackTime, 0.0);
      expect(analysis.sustainLevel, 0.0);
      expect(analysis.decayRate, 0.0);
      expect(analysis.formants, isEmpty);
      expect(analysis.spectralFlux, 0.0);
      expect(analysis.deltaMfcc, isEmpty);
      expect(analysis.deltaDeltaMfcc, isEmpty);
    });
  });

  group('AudioAnalysis.copyWith', () {
    test('copies with updated topSpeciesMatches', () {
      final original = AudioAnalysis.simple(
        frequencyHz: 500.0,
        durationSec: 2.0,
      );
      final copy = original.copyWith(
        topSpeciesMatches: {'Wild Turkey': 95.0},
      );
      expect(copy.topSpeciesMatches['Wild Turkey'], 95.0);
      expect(copy.dominantFrequencyHz, 500.0); // unchanged
    });

    test('copyWith without args preserves all fields', () {
      final original = AudioAnalysis.simple(
        frequencyHz: 720.0,
        durationSec: 3.5,
        volume: 0.7,
      );
      final copy = original.copyWith();
      expect(copy.dominantFrequencyHz, 720.0);
      expect(copy.totalDurationSec, 3.5);
      expect(copy.averageVolume, 0.7);
      expect(copy.topSpeciesMatches, isEmpty);
    });
  });

  group('AnalysisRating', () {
    test('has 4 values', () {
      expect(AnalysisRating.values.length, 4);
    });

    test('all values exist', () {
      expect(AnalysisRating.values, contains(AnalysisRating.excellent));
      expect(AnalysisRating.values, contains(AnalysisRating.good));
      expect(AnalysisRating.values, contains(AnalysisRating.fair));
      expect(AnalysisRating.values, contains(AnalysisRating.poor));
    });
  });

  group('AnalysisSummary', () {
    test('stores all required fields', () {
      final summary = AnalysisSummary(
        category: 'Pitch',
        metric: 'Frequency',
        value: 720.0,
        unit: 'Hz',
        description: 'Dominant pitch frequency',
        rating: AnalysisRating.excellent,
      );
      expect(summary.category, 'Pitch');
      expect(summary.metric, 'Frequency');
      expect(summary.value, 720.0);
      expect(summary.unit, 'Hz');
      expect(summary.rating, AnalysisRating.excellent);
    });
  });
}
