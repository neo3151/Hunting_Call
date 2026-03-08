import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:outcall/core/services/logger/logger_service.dart';
import 'package:outcall/di_providers.dart';
import 'package:outcall/features/recording/domain/audio_recorder_service.dart';

/// Represents the hardware baseline for this specific device.
class CalibrationProfile {
  final double noiseFloorDb; // The absolute lowest ambient noise detected
  final double maxVolumeDb; // The maximum safe volume before clipping
  final bool isWindy; // Flagged if the ambient noise floor is oscillating heavily
  final DateTime timestamp;

  const CalibrationProfile({
    required this.noiseFloorDb,
    required this.maxVolumeDb,
    required this.isWindy,
    required this.timestamp,
  });

  bool get requiresNoiseGating => noiseFloorDb > -45.0 || isWindy;

  // If the ambient room is louder than -30dB, it's virtually impossible
  // to get a clean biological acoustic reading.
  bool get environmentalNoiseTooHigh => noiseFloorDb > -30.0;
}

abstract class MicCalibrationService {
  /// Runs a 3-second hardware calibration check.
  /// Must be called before any professional scoring session.
  Future<CalibrationProfile> executePreFlightCheck();

  /// Gets the last known calibration profile.
  CalibrationProfile? get currentProfile;
}

class MicCalibrationServiceImpl implements MicCalibrationService {
  final AudioRecorderService _recorder;
  final LoggerService _logger;

  CalibrationProfile? _currentProfile;

  MicCalibrationServiceImpl(this._recorder, this._logger);

  @override
  CalibrationProfile? get currentProfile => _currentProfile;

  @override
  Future<CalibrationProfile> executePreFlightCheck() async {
    _logger.log('Starting Mic Calibration Pre-Flight Check...');

    // We expect the user is in a quiet room or the woods.
    // 1. Ask the hardware to start listening purely for amplitude, not saving to file.
    // Actually our current recorder expects a file path. We'll use a temp file
    // and delete it immediately after calibration.

    const tempPath = '/data/user/0/com.neo3151.outcall/cache/calibration_temp.wav';

    try {
      await _recorder.startRecorder(tempPath);

      final amplitudes = <double>[];

      // Sample for exactly 3 seconds
      final sub = _recorder.onAmplitudeChanged.listen((amp) {
        amplitudes.add(amp);
      });

      await Future.delayed(const Duration(seconds: 3));

      await sub.cancel();
      await _recorder.stopRecorder();

      // Calculate calibration metrics
      if (amplitudes.isEmpty) {
        throw Exception('Calibration Failed: No audio data received from hardware.');
      }

      double sum = 0;
      double maxAmp = -160.0;
      double minAmp = 0.0;

      for (final a in amplitudes) {
        sum += a;
        if (a > maxAmp) maxAmp = a;
        if (a < minAmp) minAmp = a;
      }

      final avgAmplitude = sum / amplitudes.length;

      // Detect wind / oscillating background hum (variance)
      double varianceSum = 0;
      for (final a in amplitudes) {
        varianceSum += (a - avgAmplitude) * (a - avgAmplitude);
      }
      final variance = varianceSum / amplitudes.length;

      // A high variance in a "silent" room indicates wind blasting the mic capsule
      final isWindy = variance > 50.0;

      _currentProfile = CalibrationProfile(
        noiseFloorDb: avgAmplitude,
        maxVolumeDb: maxAmp,
        isWindy: isWindy,
        timestamp: DateTime.now(),
      );

      _logger.log(
          'Calibration Complete | Noise Floor: ${avgAmplitude.toStringAsFixed(1)}dB | Windy: $isWindy');

      return _currentProfile!;
    } catch (e) {
      _logger.recordError(e, StackTrace.current, reason: 'Calibration crashed');
      _recorder.stopRecorder(); // Failsafe

      // Fallback safe profile if hardware refuses to calibrate
      _currentProfile = CalibrationProfile(
        noiseFloorDb: -60.0,
        maxVolumeDb: 0.0,
        isWindy: false,
        timestamp: DateTime.now(),
      );
      return _currentProfile!;
    }
  }
}

final micCalibrationServiceProvider = Provider<MicCalibrationService>((ref) {
  return MicCalibrationServiceImpl(
    ref.watch(audioRecorderServiceProvider),
    ref.watch(loggerServiceProvider),
  );
});
