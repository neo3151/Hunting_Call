import 'package:flutter_test/flutter_test.dart';
import 'package:outcall/features/analysis/domain/audio_analysis_model.dart';

void main() {
  AudioAnalysis _makeFullAnalysis() {
    return AudioAnalysis(
      dominantFrequencyHz: 440.0,
      averageFrequencyHz: 435.0,
      frequencyPeaks: [440.0, 880.0, 1320.0],
      pitchStability: 85.0,
      pitchTrack: [430.0, 440.0, 445.0, 440.0],
      averageVolume: 0.65,
      peakVolume: 0.92,
      volumeConsistency: 78.0,
      toneClarity: 88.0,
      harmonicRichness: 72.0,
      harmonics: {'H1': 440.0, 'H2': 880.0, 'H3': 1320.0},
      brightness: 62.0,
      warmth: 55.0,
      nasality: 30.0,
      spectralCentroid: [2000.0, 2100.0, 1950.0],
      totalDurationSec: 3.5,
      activeDurationSec: 3.0,
      silenceDurationSec: 0.5,
      tempo: 120.0,
      pulseTimes: [0.5, 1.0, 1.5, 2.0],
      rhythmRegularity: 90.0,
      isPulsedCall: true,
      callQualityScore: 82.0,
      noiseLevel: 15.0,
      mfccCoefficients: List.generate(13, (i) => i * 1.5),
      waveform: List.generate(100, (i) => (i % 10) / 10.0),
    );
  }

  group('AudioAnalysis', () {
    test('constructs with all required fields', () {
      final analysis = _makeFullAnalysis();

      expect(analysis.dominantFrequencyHz, 440.0);
      expect(analysis.averageFrequencyHz, 435.0);
      expect(analysis.frequencyPeaks, hasLength(3));
      expect(analysis.pitchStability, 85.0);
      expect(analysis.pitchTrack, hasLength(4));
      expect(analysis.averageVolume, 0.65);
      expect(analysis.peakVolume, 0.92);
      expect(analysis.volumeConsistency, 78.0);
      expect(analysis.toneClarity, 88.0);
      expect(analysis.harmonicRichness, 72.0);
      expect(analysis.harmonics, hasLength(3));
      expect(analysis.brightness, 62.0);
      expect(analysis.warmth, 55.0);
      expect(analysis.nasality, 30.0);
      expect(analysis.spectralCentroid, hasLength(3));
      expect(analysis.totalDurationSec, 3.5);
      expect(analysis.activeDurationSec, 3.0);
      expect(analysis.silenceDurationSec, 0.5);
      expect(analysis.tempo, 120.0);
      expect(analysis.pulseTimes, hasLength(4));
      expect(analysis.rhythmRegularity, 90.0);
      expect(analysis.isPulsedCall, isTrue);
      expect(analysis.callQualityScore, 82.0);
      expect(analysis.noiseLevel, 15.0);
      expect(analysis.mfccCoefficients, hasLength(13));
      expect(analysis.waveform, hasLength(100));
    });

    test('JSON roundtrip preserves all fields', () {
      final original = _makeFullAnalysis();
      final json = original.toJson();
      final restored = AudioAnalysis.fromJson(json);

      expect(restored.dominantFrequencyHz, original.dominantFrequencyHz);
      expect(restored.averageFrequencyHz, original.averageFrequencyHz);
      expect(restored.frequencyPeaks, original.frequencyPeaks);
      expect(restored.pitchStability, original.pitchStability);
      expect(restored.pitchTrack, original.pitchTrack);
      expect(restored.averageVolume, original.averageVolume);
      expect(restored.peakVolume, original.peakVolume);
      expect(restored.volumeConsistency, original.volumeConsistency);
      expect(restored.toneClarity, original.toneClarity);
      expect(restored.harmonicRichness, original.harmonicRichness);
      expect(restored.harmonics, original.harmonics);
      expect(restored.brightness, original.brightness);
      expect(restored.warmth, original.warmth);
      expect(restored.nasality, original.nasality);
      expect(restored.spectralCentroid, original.spectralCentroid);
      expect(restored.totalDurationSec, original.totalDurationSec);
      expect(restored.activeDurationSec, original.activeDurationSec);
      expect(restored.silenceDurationSec, original.silenceDurationSec);
      expect(restored.tempo, original.tempo);
      expect(restored.pulseTimes, original.pulseTimes);
      expect(restored.rhythmRegularity, original.rhythmRegularity);
      expect(restored.isPulsedCall, original.isPulsedCall);
      expect(restored.callQualityScore, original.callQualityScore);
      expect(restored.noiseLevel, original.noiseLevel);
      expect(restored.mfccCoefficients, original.mfccCoefficients);
      expect(restored.waveform, original.waveform);
    });

    test('toJson produces correct keys', () {
      final json = _makeFullAnalysis().toJson();

      expect(json.containsKey('dominantFrequencyHz'), isTrue);
      expect(json.containsKey('averageFrequencyHz'), isTrue);
      expect(json.containsKey('frequencyPeaks'), isTrue);
      expect(json.containsKey('pitchStability'), isTrue);
      expect(json.containsKey('isPulsedCall'), isTrue);
      expect(json.containsKey('mfccCoefficients'), isTrue);
      expect(json.containsKey('waveform'), isTrue);
    });
  });

  group('AudioAnalysis.simple', () {
    test('creates with minimal params', () {
      final s = AudioAnalysis.simple(frequencyHz: 500.0, durationSec: 2.0);

      expect(s.dominantFrequencyHz, 500.0);
      expect(s.averageFrequencyHz, 500.0);
      expect(s.frequencyPeaks, [500.0]);
      expect(s.totalDurationSec, 2.0);
      expect(s.activeDurationSec, closeTo(1.8, 0.01));
      expect(s.silenceDurationSec, closeTo(0.2, 0.01));
    });

    test('uses default volume = 0.5', () {
      final s = AudioAnalysis.simple(frequencyHz: 500.0, durationSec: 2.0);

      expect(s.averageVolume, 0.5);
      expect(s.peakVolume, 0.75);
    });

    test('custom volume is applied', () {
      final s = AudioAnalysis.simple(frequencyHz: 500.0, durationSec: 2.0, volume: 0.8);

      expect(s.averageVolume, 0.8);
      expect(s.peakVolume, closeTo(1.2, 0.01));
    });

    test('defaults to non-pulsed call', () {
      final s = AudioAnalysis.simple(frequencyHz: 500.0, durationSec: 2.0);

      expect(s.isPulsedCall, isFalse);
      expect(s.pulseTimes, isEmpty);
      expect(s.tempo, 0.0);
    });

    test('default quality scores are middling', () {
      final s = AudioAnalysis.simple(frequencyHz: 500.0, durationSec: 2.0);

      expect(s.pitchStability, 50.0);
      expect(s.volumeConsistency, 50.0);
      expect(s.toneClarity, 50.0);
      expect(s.callQualityScore, 50.0);
      expect(s.noiseLevel, 20.0);
    });

    test('waveform has 100 elements', () {
      final s = AudioAnalysis.simple(frequencyHz: 500.0, durationSec: 2.0);
      expect(s.waveform, hasLength(100));
    });

    test('simple analysis JSON roundtrip', () {
      final original = AudioAnalysis.simple(frequencyHz: 1000.0, durationSec: 5.0);
      final json = original.toJson();
      final restored = AudioAnalysis.fromJson(json);

      expect(restored.dominantFrequencyHz, original.dominantFrequencyHz);
      expect(restored.totalDurationSec, original.totalDurationSec);
      expect(restored.isPulsedCall, original.isPulsedCall);
    });
  });

  group('AnalysisSummary', () {
    test('constructs with all fields', () {
      final summary = AnalysisSummary(
        category: 'Pitch',
        metric: 'Dominant Frequency',
        value: 440.0,
        unit: 'Hz',
        description: 'The main frequency detected',
        rating: AnalysisRating.excellent,
      );

      expect(summary.category, 'Pitch');
      expect(summary.metric, 'Dominant Frequency');
      expect(summary.value, 440.0);
      expect(summary.unit, 'Hz');
      expect(summary.description, 'The main frequency detected');
      expect(summary.rating, AnalysisRating.excellent);
    });
  });

  group('AnalysisRating', () {
    test('has 4 values', () {
      expect(AnalysisRating.values, hasLength(4));
    });

    test('values are in order', () {
      expect(AnalysisRating.values, [
        AnalysisRating.excellent,
        AnalysisRating.good,
        AnalysisRating.fair,
        AnalysisRating.poor,
      ]);
    });
  });
}
