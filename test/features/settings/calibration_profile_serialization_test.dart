import 'package:flutter_test/flutter_test.dart';
import 'package:outcall/features/settings/domain/calibration_profile.dart';

void main() {
  group('CalibrationProfile', () {
    test('defaults are correct', () {
      const profile = CalibrationProfile();
      expect(profile.scoreOffset, 0.0);
      expect(profile.micSensitivity, 1.0);
      expect(profile.noiseFloorLevel, 0.0);
      expect(profile.calibratedAt, isNull);
      expect(profile.isCalibrated, false);
    });

    test('isCalibrated returns true when calibratedAt is set', () {
      final profile = CalibrationProfile(
        calibratedAt: DateTime(2026, 3, 13),
      );
      expect(profile.isCalibrated, true);
    });

    test('copyWith preserves unchanged fields', () {
      final original = CalibrationProfile(
        scoreOffset: 5.0,
        micSensitivity: 1.2,
        noiseFloorLevel: 0.1,
        calibratedAt: DateTime(2026, 3, 13),
      );
      final copy = original.copyWith(scoreOffset: 10.0);
      expect(copy.scoreOffset, 10.0);
      expect(copy.micSensitivity, 1.2);
      expect(copy.noiseFloorLevel, 0.1);
      expect(copy.isCalibrated, true);
    });

    test('toMap serializes correctly', () {
      final profile = CalibrationProfile(
        scoreOffset: 3.5,
        micSensitivity: 0.8,
        noiseFloorLevel: 0.05,
        calibratedAt: DateTime(2026, 3, 13, 10, 30),
      );
      final map = profile.toMap();
      expect(map['scoreOffset'], 3.5);
      expect(map['micSensitivity'], 0.8);
      expect(map['noiseFloorLevel'], 0.05);
      expect(map['calibratedAt'], contains('2026-03-13'));
    });

    test('toMap with null calibratedAt', () {
      const profile = CalibrationProfile();
      final map = profile.toMap();
      expect(map['calibratedAt'], isNull);
    });

    test('fromMap restores correctly', () {
      final map = {
        'scoreOffset': 5.0,
        'micSensitivity': 1.5,
        'noiseFloorLevel': 0.1,
        'calibratedAt': '2026-03-13T10:30:00.000',
      };
      final profile = CalibrationProfile.fromMap(map);
      expect(profile.scoreOffset, 5.0);
      expect(profile.micSensitivity, 1.5);
      expect(profile.noiseFloorLevel, 0.1);
      expect(profile.calibratedAt, isNotNull);
      expect(profile.isCalibrated, true);
    });

    test('fromMap handles missing fields with defaults', () {
      final profile = CalibrationProfile.fromMap({});
      expect(profile.scoreOffset, 0.0);
      expect(profile.micSensitivity, 1.0);
      expect(profile.noiseFloorLevel, 0.0);
      expect(profile.calibratedAt, isNull);
    });

    test('fromMap handles integer values (num → double)', () {
      final map = {
        'scoreOffset': 5,
        'micSensitivity': 2,
        'noiseFloorLevel': 0,
      };
      final profile = CalibrationProfile.fromMap(map);
      expect(profile.scoreOffset, 5.0);
      expect(profile.micSensitivity, 2.0);
    });

    test('toMap → fromMap round-trip', () {
      final original = CalibrationProfile(
        scoreOffset: -10.0,
        micSensitivity: 0.6,
        noiseFloorLevel: 0.15,
        calibratedAt: DateTime(2026, 1, 1),
      );
      final roundTripped = CalibrationProfile.fromMap(original.toMap());
      expect(roundTripped.scoreOffset, original.scoreOffset);
      expect(roundTripped.micSensitivity, original.micSensitivity);
      expect(roundTripped.noiseFloorLevel, original.noiseFloorLevel);
      expect(roundTripped.isCalibrated, original.isCalibrated);
    });
  });
}
