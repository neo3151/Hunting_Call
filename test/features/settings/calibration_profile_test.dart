import 'package:flutter_test/flutter_test.dart';
import 'package:outcall/features/settings/domain/calibration_profile.dart';

void main() {
  group('CalibrationProfile', () {
    test('default values are neutral', () {
      const cal = CalibrationProfile();
      expect(cal.scoreOffset, 0.0);
      expect(cal.micSensitivity, 1.0);
      expect(cal.noiseFloorLevel, 0.0);
      expect(cal.calibratedAt, isNull);
      expect(cal.isCalibrated, isFalse);
    });

    test('copyWith preserves unchanged fields', () {
      final cal = CalibrationProfile(
        scoreOffset: 5.0,
        micSensitivity: 1.3,
        noiseFloorLevel: 0.12,
        calibratedAt: DateTime(2026, 3, 4),
      );
      final updated = cal.copyWith(scoreOffset: -10.0);
      expect(updated.scoreOffset, -10.0);
      expect(updated.micSensitivity, 1.3);
      expect(updated.noiseFloorLevel, 0.12);
      expect(updated.calibratedAt, DateTime(2026, 3, 4));
    });

    test('toMap / fromMap roundtrip', () {
      final original = CalibrationProfile(
        scoreOffset: 15.0,
        micSensitivity: 0.7,
        noiseFloorLevel: 0.25,
        calibratedAt: DateTime(2026, 3, 4, 12, 30),
      );

      final map = original.toMap();
      final restored = CalibrationProfile.fromMap(map);

      expect(restored.scoreOffset, original.scoreOffset);
      expect(restored.micSensitivity, original.micSensitivity);
      expect(restored.noiseFloorLevel, original.noiseFloorLevel);
      expect(restored.calibratedAt, original.calibratedAt);
      expect(restored.isCalibrated, isTrue);
    });

    test('fromMap handles missing/null fields gracefully', () {
      final cal = CalibrationProfile.fromMap({});
      expect(cal.scoreOffset, 0.0);
      expect(cal.micSensitivity, 1.0);
      expect(cal.noiseFloorLevel, 0.0);
      expect(cal.calibratedAt, isNull);
    });

    test('isCalibrated returns true when calibratedAt is set', () {
      final cal = CalibrationProfile(calibratedAt: DateTime.now());
      expect(cal.isCalibrated, isTrue);
    });

    test('score offset is bounded by convention (-20 to +20)', () {
      // Not enforced in model, but tested for documentation
      const cal = CalibrationProfile(scoreOffset: 20.0);
      expect(cal.scoreOffset, 20.0);
      const cal2 = CalibrationProfile(scoreOffset: -20.0);
      expect(cal2.scoreOffset, -20.0);
    });

    test('mic sensitivity range (0.5 to 2.0)', () {
      const cal = CalibrationProfile(micSensitivity: 0.5);
      expect(cal.micSensitivity, 0.5);
      const cal2 = CalibrationProfile(micSensitivity: 2.0);
      expect(cal2.micSensitivity, 2.0);
    });
  });
}
