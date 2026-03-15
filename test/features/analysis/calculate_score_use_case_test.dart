import 'package:flutter_test/flutter_test.dart';
import 'package:outcall/features/analysis/domain/use_cases/calculate_score_use_case.dart';
import 'package:outcall/features/analysis/domain/audio_analysis_model.dart';
import 'package:outcall/features/analysis/domain/failures/analysis_failure.dart';
import 'package:outcall/features/library/domain/reference_call_model.dart';
import 'package:outcall/features/library/data/reference_database.dart';

void main() {
  // Seed the ReferenceDatabase with test data before every test
  setUp(() {
    ReferenceDatabase.calls = [
      const ReferenceCall(
        id: 'elk_bugle',
        animalName: 'Rocky Mountain Elk',
        callType: 'Bugle',
        category: 'Big Game',
        difficulty: 'Pro',
        idealPitchHz: 720.0,
        idealDurationSec: 3.5,
        audioAssetPath: 'audio/elk.mp3',
        tolerancePitch: 50.0,
        toleranceDuration: 0.5,
      ),
      const ReferenceCall(
        id: 'duck_quack',
        animalName: 'Mallard Duck',
        callType: 'Quack',
        category: 'Waterfowl',
        difficulty: 'Easy',
        idealPitchHz: 500.0,
        idealDurationSec: 1.5,
        audioAssetPath: 'audio/duck.mp3',
        tolerancePitch: 30.0,
        toleranceDuration: 0.5,
        isPulsedCall: true,
        idealTempo: 120.0,
      ),
    ];
  });

  group('CalculateScoreParams', () {
    test('stores all required fields', () {
      final analysis = AudioAnalysis.simple(frequencyHz: 720.0, durationSec: 3.5);
      final params = CalculateScoreParams(
        userId: 'user_1',
        recordingId: 'rec_1',
        animalId: 'elk_bugle',
        userAnalysis: analysis,
      );
      expect(params.userId, 'user_1');
      expect(params.recordingId, 'rec_1');
      expect(params.animalId, 'elk_bugle');
      expect(params.scoreOffset, 0.0);
      expect(params.micSensitivity, 1.0);
      expect(params.fingerprintMatchPercent, isNull);
      expect(params.userBaseline, isNull);
    });

    test('custom calibration values', () {
      final analysis = AudioAnalysis.simple(frequencyHz: 720.0, durationSec: 3.5);
      final params = CalculateScoreParams(
        userId: 'user_1',
        recordingId: 'rec_1',
        animalId: 'elk_bugle',
        userAnalysis: analysis,
        scoreOffset: 5.0,
        micSensitivity: 1.2,
      );
      expect(params.scoreOffset, 5.0);
      expect(params.micSensitivity, 1.2);
    });
  });

  group('CalculateScoreUseCase', () {
    const useCase = CalculateScoreUseCase();

    test('returns InsufficientAudioData for silent recording', () async {
      final silentAnalysis = AudioAnalysis.simple(
        frequencyHz: 0.0,
        durationSec: 0.0,
        volume: 0.0,
      );
      final result = await useCase.execute(CalculateScoreParams(
        userId: 'u1',
        recordingId: 'r1',
        animalId: 'elk_bugle',
        userAnalysis: silentAnalysis,
      ));
      result.fold(
        (failure) => expect(failure, isA<InsufficientAudioData>()),
        (success) => fail('Should have returned failure'),
      );
    });

    test('effectively silent recording (<0.005 volume) returns score 0', () async {
      final quietAnalysis = AudioAnalysis.simple(
        frequencyHz: 720.0,
        durationSec: 3.5,
        volume: 0.001,
      );
      final result = await useCase.execute(CalculateScoreParams(
        userId: 'u1',
        recordingId: 'r1',
        animalId: 'elk_bugle',
        userAnalysis: quietAnalysis,
      ));
      result.fold(
        (failure) => fail('Should have returned success with score 0'),
        (success) {
          expect(success.overallScore, 0.0);
          expect(success.recordingId, 'r1');
        },
      );
    });

    test('perfect pitch on elk gives high pitch score', () async {
      final analysis = AudioAnalysis.simple(
        frequencyHz: 720.0,
        durationSec: 3.5,
        volume: 0.5,
      );
      final result = await useCase.execute(CalculateScoreParams(
        userId: 'u1',
        recordingId: 'r1',
        animalId: 'elk_bugle',
        userAnalysis: analysis,
      ));
      result.fold(
        (failure) => fail('Should not fail: ${failure.message}'),
        (success) {
          expect(success.pitchScore.score, greaterThanOrEqualTo(90.0));
          expect(success.overallScore, greaterThan(0));
        },
      );
    });

    test('way-off pitch gives lower score', () async {
      final analysis = AudioAnalysis.simple(
        frequencyHz: 200.0, // Way off from 720 Hz
        durationSec: 3.5,
        volume: 0.5,
      );
      final result = await useCase.execute(CalculateScoreParams(
        userId: 'u1',
        recordingId: 'r1',
        animalId: 'elk_bugle',
        userAnalysis: analysis,
      ));
      result.fold(
        (failure) => fail('Should not fail'),
        (success) {
          expect(success.pitchScore.score, lessThan(50.0));
        },
      );
    });

    test('score offset calibration is applied', () async {
      final analysis = AudioAnalysis.simple(
        frequencyHz: 720.0,
        durationSec: 3.5,
        volume: 0.5,
      );
      final without = await useCase.execute(CalculateScoreParams(
        userId: 'u1',
        recordingId: 'r1',
        animalId: 'elk_bugle',
        userAnalysis: analysis,
        scoreOffset: 0.0,
      ));
      final withOffset = await useCase.execute(CalculateScoreParams(
        userId: 'u1',
        recordingId: 'r2',
        animalId: 'elk_bugle',
        userAnalysis: analysis,
        scoreOffset: 10.0,
      ));
      final scoreWithout = without.getOrElse((l) => throw l);
      final scoreWith = withOffset.getOrElse((l) => throw l);
      expect(scoreWith.overallScore, greaterThan(scoreWithout.overallScore));
    });

    test('score is clamped between 0 and 100', () async {
      final analysis = AudioAnalysis.simple(
        frequencyHz: 720.0,
        durationSec: 3.5,
        volume: 0.5,
      );
      final result = await useCase.execute(CalculateScoreParams(
        userId: 'u1',
        recordingId: 'r1',
        animalId: 'elk_bugle',
        userAnalysis: analysis,
        scoreOffset: 100.0, // Extreme offset
      ));
      result.fold(
        (failure) => fail('Should not fail'),
        (success) {
          expect(success.overallScore, lessThanOrEqualTo(100.0));
          expect(success.overallScore, greaterThanOrEqualTo(0.0));
        },
      );
    });

    test('signal quality floor: decent signal gets at least 25', () async {
      // A recording with decent volume and duration but terrible pitch
      final analysis = AudioAnalysis.simple(
        frequencyHz: 50.0, // Way off from any target
        durationSec: 3.5,
        volume: 0.1, // Above 0.02 threshold
      );
      final result = await useCase.execute(CalculateScoreParams(
        userId: 'u1',
        recordingId: 'r1',
        animalId: 'elk_bugle',
        userAnalysis: analysis,
      ));
      result.fold(
        (failure) => fail('Should not fail'),
        (success) {
          expect(success.overallScore, greaterThanOrEqualTo(25.0));
        },
      );
    });

    test('user baseline improvement bonus', () async {
      final analysis = AudioAnalysis.simple(
        frequencyHz: 720.0,
        durationSec: 3.5,
        volume: 0.5,
      );
      final withoutBaseline = await useCase.execute(CalculateScoreParams(
        userId: 'u1',
        recordingId: 'r1',
        animalId: 'elk_bugle',
        userAnalysis: analysis,
      ));
      final withBaseline = await useCase.execute(CalculateScoreParams(
        userId: 'u1',
        recordingId: 'r2',
        animalId: 'elk_bugle',
        userAnalysis: analysis,
        userBaseline: [30.0, 35.0, 40.0], // Low baseline → big improvement
      ));
      final scoreWithout = withoutBaseline.getOrElse((l) => throw l);
      final scoreWith = withBaseline.getOrElse((l) => throw l);
      // With low baseline, the user should get a bonus
      expect(scoreWith.overallScore, greaterThanOrEqualTo(scoreWithout.overallScore));
    });

    test('fingerprint match percentage used when available', () async {
      final analysis = AudioAnalysis.simple(
        frequencyHz: 720.0,
        durationSec: 3.5,
        volume: 0.5,
      );
      final withFingerprint = await useCase.execute(CalculateScoreParams(
        userId: 'u1',
        recordingId: 'r1',
        animalId: 'elk_bugle',
        userAnalysis: analysis,
        fingerprintMatchPercent: 95.0,
      ));
      withFingerprint.fold(
        (failure) => fail('Should not fail'),
        (success) {
          expect(success.fingerprintMatchPercent, 95.0);
        },
      );
    });

    test('result includes all dimension scores', () async {
      final analysis = AudioAnalysis.simple(
        frequencyHz: 720.0,
        durationSec: 3.5,
        volume: 0.5,
      );
      final result = await useCase.execute(CalculateScoreParams(
        userId: 'u1',
        recordingId: 'r1',
        animalId: 'elk_bugle',
        userAnalysis: analysis,
      ));
      result.fold(
        (failure) => fail('Should not fail'),
        (success) {
          expect(success.pitchScore, isNotNull);
          expect(success.volumeScore, isNotNull);
          expect(success.durationScore, isNotNull);
          expect(success.toneScore, isNotNull);
          expect(success.rhythmScore, isNotNull);
          expect(success.pitchContourScore, isNotNull);
          expect(success.envelopeScore, isNotNull);
          expect(success.formantScore, isNotNull);
          expect(success.noiseScore, isNotNull);
        },
      );
    });
  });
}
