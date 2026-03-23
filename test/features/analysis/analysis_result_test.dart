import 'package:flutter_test/flutter_test.dart';
import 'package:outcall/features/analysis/domain/entities/analysis_result.dart';

void main() {
  group('Analysis Score Models', () {
    group('PitchScore', () {
      test('stores all properties', () {
        const score = PitchScore(score: 85.0, actualHz: 720.0, idealHz: 700.0, deviation: 20.0);
        expect(score.score, 85.0);
        expect(score.actualHz, 720.0);
        expect(score.idealHz, 700.0);
        expect(score.deviation, 20.0);
      });

      test('toString includes key values', () {
        const score = PitchScore(score: 90.0, actualHz: 500.0, idealHz: 510.0, deviation: 10.0);
        expect(score.toString(), contains('90'));
        expect(score.toString(), contains('500'));
      });
    });

    group('DurationScore', () {
      test('stores all properties', () {
        const score = DurationScore(score: 75.0, actualSec: 2.5, idealSec: 3.0, deviation: 0.5);
        expect(score.score, 75.0);
        expect(score.actualSec, 2.5);
        expect(score.idealSec, 3.0);
      });
    });

    group('VolumeScore', () {
      test('stores all properties', () {
        const score = VolumeScore(score: 80.0, volumeDb: -12.0, consistency: 0.9);
        expect(score.score, 80.0);
        expect(score.volumeDb, -12.0);
        expect(score.consistency, 0.9);
      });
    });

    group('ToneScore', () {
      test('stores all properties', () {
        const score = ToneScore(score: 70.0, brightness: 0.6, warmth: 0.8, nasality: 0.2);
        expect(score.score, 70.0);
        expect(score.brightness, 0.6);
        expect(score.warmth, 0.8);
        expect(score.nasality, 0.2);
      });
    });

    group('RhythmScore', () {
      test('stores all properties', () {
        const score = RhythmScore(score: 65.0, stability: 0.7, regularity: 0.8, tempo: 120.0);
        expect(score.score, 65.0);
        expect(score.stability, 0.7);
        expect(score.tempo, 120.0);
      });
    });

    group('PitchContourScore', () {
      test('defaults optional fields to 0', () {
        const score = PitchContourScore(score: 80.0);
        expect(score.contourSimilarity, 0);
        expect(score.flatnessDeviation, 0);
      });
    });

    group('EnvelopeScore', () {
      test('defaults ADSR matches to 0', () {
        const score = EnvelopeScore(score: 75.0);
        expect(score.attackMatch, 0);
        expect(score.sustainMatch, 0);
        expect(score.decayMatch, 0);
      });

      test('stores explicit ADSR values', () {
        const score = EnvelopeScore(score: 90.0, attackMatch: 85, sustainMatch: 92, decayMatch: 88);
        expect(score.attackMatch, 85);
      });
    });

    group('FormantScore', () {
      test('defaults formant lists to empty', () {
        const score = FormantScore(score: 70.0);
        expect(score.userFormants, isEmpty);
        expect(score.refFormants, isEmpty);
      });
    });

    group('NoiseScore', () {
      test('defaults spectralFlux to 0', () {
        const score = NoiseScore(score: 60.0);
        expect(score.spectralFlux, 0);
      });
    });
  });

  group('AnalysisResult', () {
    final now = DateTime(2026, 3, 13);

    AnalysisResult makeAnalysisResult({String id = 'rec_1', double score = 80.0}) {
      return AnalysisResult(
        recordingId: id,
        userId: 'user_1',
        animalId: 'elk_bugle',
        overallScore: score,
        pitchScore: const PitchScore(score: 80, actualHz: 700, idealHz: 700, deviation: 0),
        volumeScore: const VolumeScore(score: 80, volumeDb: -10, consistency: 0.9),
        durationScore: const DurationScore(score: 80, actualSec: 3.0, idealSec: 3.0, deviation: 0),
        toneScore: const ToneScore(score: 80, brightness: 0.5, warmth: 0.5, nasality: 0.2),
        rhythmScore: const RhythmScore(score: 80, stability: 0.8, regularity: 0.9, tempo: 100),
        analyzedAt: now,
      );
    }

    test('stores all required fields', () {
      final result = makeAnalysisResult();
      expect(result.recordingId, 'rec_1');
      expect(result.userId, 'user_1');
      expect(result.animalId, 'elk_bugle');
      expect(result.overallScore, 80.0);
      expect(result.analyzedAt, now);
    });

    test('defaults new dimension scores to 0', () {
      final result = makeAnalysisResult();
      expect(result.pitchContourScore.score, 0);
      expect(result.envelopeScore.score, 0);
      expect(result.formantScore.score, 0);
      expect(result.noiseScore.score, 0);
      expect(result.fingerprintMatchPercent, isNull);
    });

    test('equality by recordingId only', () {
      final a = makeAnalysisResult(id: 'rec_1', score: 80.0);
      final b = makeAnalysisResult(id: 'rec_1', score: 90.0);
      expect(a, equals(b)); // Same ID = equal
    });

    test('different recordingId means not equal', () {
      final a = makeAnalysisResult(id: 'rec_1');
      final b = makeAnalysisResult(id: 'rec_2');
      expect(a, isNot(equals(b)));
    });

    test('hashCode based on recordingId', () {
      final a = makeAnalysisResult(id: 'rec_1');
      expect(a.hashCode, 'rec_1'.hashCode);
    });

    test('toString includes key info', () {
      final result = makeAnalysisResult();
      expect(result.toString(), contains('rec_1'));
      expect(result.toString(), contains('80'));
      expect(result.toString(), contains('elk_bugle'));
    });
  });
}
