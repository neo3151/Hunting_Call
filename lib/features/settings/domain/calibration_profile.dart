/// On-device calibration profile for scoring adjustments.
///
/// Allows users to fine-tune scoring when their device's microphone
/// characteristics cause scores to be consistently off.
class CalibrationProfile {
  /// Score offset added to the final overall score (-20 to +20).
  final double scoreOffset;

  /// Multiplier for volume/amplitude readings (0.5 to 2.0).
  /// Compensates for mic sensitivity differences across devices.
  final double micSensitivity;

  /// Measured ambient noise floor in normalized amplitude (0.0 to 1.0).
  /// Captured during the calibration noise test.
  final double noiseFloorLevel;

  /// When this calibration was last performed.
  final DateTime? calibratedAt;

  const CalibrationProfile({
    this.scoreOffset = 0.0,
    this.micSensitivity = 1.0,
    this.noiseFloorLevel = 0.0,
    this.calibratedAt,
  });

  CalibrationProfile copyWith({
    double? scoreOffset,
    double? micSensitivity,
    double? noiseFloorLevel,
    DateTime? calibratedAt,
  }) {
    return CalibrationProfile(
      scoreOffset: scoreOffset ?? this.scoreOffset,
      micSensitivity: micSensitivity ?? this.micSensitivity,
      noiseFloorLevel: noiseFloorLevel ?? this.noiseFloorLevel,
      calibratedAt: calibratedAt ?? this.calibratedAt,
    );
  }

  Map<String, dynamic> toMap() => {
        'scoreOffset': scoreOffset,
        'micSensitivity': micSensitivity,
        'noiseFloorLevel': noiseFloorLevel,
        'calibratedAt': calibratedAt?.toIso8601String(),
      };

  factory CalibrationProfile.fromMap(Map<String, dynamic> map) {
    return CalibrationProfile(
      scoreOffset: (map['scoreOffset'] as num?)?.toDouble() ?? 0.0,
      micSensitivity: (map['micSensitivity'] as num?)?.toDouble() ?? 1.0,
      noiseFloorLevel: (map['noiseFloorLevel'] as num?)?.toDouble() ?? 0.0,
      calibratedAt: map['calibratedAt'] != null
          ? DateTime.tryParse(map['calibratedAt'] as String)
          : null,
    );
  }

  /// Whether calibration has been performed at least once.
  bool get isCalibrated => calibratedAt != null;
}
