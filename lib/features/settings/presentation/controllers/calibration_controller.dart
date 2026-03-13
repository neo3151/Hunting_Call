import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:outcall/features/settings/domain/calibration_profile.dart';
import 'package:outcall/features/settings/presentation/controllers/settings_controller.dart';
import 'package:record/record.dart';

// ─── State ──────────────────────────────────────────────────────────────────

@immutable
class CalibrationState {
  final double scoreOffset;
  final double micSensitivity;
  final double noiseFloorLevel;
  final bool isMeasuring;
  final bool noiseMeasured;
  final String statusText;

  const CalibrationState({
    this.scoreOffset = 0.0,
    this.micSensitivity = 1.0,
    this.noiseFloorLevel = 0.0,
    this.isMeasuring = false,
    this.noiseMeasured = false,
    this.statusText = '',
  });

  CalibrationState copyWith({
    double? scoreOffset,
    double? micSensitivity,
    double? noiseFloorLevel,
    bool? isMeasuring,
    bool? noiseMeasured,
    String? statusText,
  }) {
    return CalibrationState(
      scoreOffset: scoreOffset ?? this.scoreOffset,
      micSensitivity: micSensitivity ?? this.micSensitivity,
      noiseFloorLevel: noiseFloorLevel ?? this.noiseFloorLevel,
      isMeasuring: isMeasuring ?? this.isMeasuring,
      noiseMeasured: noiseMeasured ?? this.noiseMeasured,
      statusText: statusText ?? this.statusText,
    );
  }
}

// ─── Notifier ───────────────────────────────────────────────────────────────

class CalibrationNotifier extends Notifier<CalibrationState> {
  @override
  CalibrationState build() {
    // Load existing calibration from settings
    final settingsAsync = ref.read(settingsNotifierProvider);
    final settings = settingsAsync.when(
      data: (s) => s,
      loading: () => null,
      error: (_, __) => null,
    );
    if (settings != null) {
      final cal = settings.calibration;
      return CalibrationState(
        scoreOffset: cal.scoreOffset,
        micSensitivity: cal.micSensitivity,
        noiseFloorLevel: cal.noiseFloorLevel,
        noiseMeasured: cal.isCalibrated,
      );
    }
    return const CalibrationState();
  }

  void setScoreOffset(double value) {
    state = state.copyWith(scoreOffset: value);
  }

  void setMicSensitivity(double value) {
    state = state.copyWith(micSensitivity: value);
  }

  Future<void> measureNoiseFloor() async {
    state = state.copyWith(isMeasuring: true, statusText: 'Recording ambient noise...');

    final recorder = AudioRecorder();

    try {
      if (!await recorder.hasPermission()) {
        state = state.copyWith(isMeasuring: false, statusText: 'Microphone permission denied.');
        return;
      }

      await recorder.start(
        const RecordConfig(encoder: AudioEncoder.wav, numChannels: 1, sampleRate: 44100),
        path: '${(await Directory.systemTemp.createTemp('cal_')).path}/noise_test.wav',
      );

      int remaining = 3;
      while (remaining > 0) {
        state = state.copyWith(statusText: 'Keep quiet... ${remaining}s remaining');
        await Future.delayed(const Duration(seconds: 1));
        remaining--;
      }

      final amplitude = await recorder.getAmplitude();
      await recorder.stop();
      await recorder.dispose();

      final dBFS = amplitude.current;
      final normalized = ((dBFS + 60) / 60).clamp(0.0, 1.0);

      double newSensitivity;
      String newStatus;
      if (normalized > 0.3) {
        newSensitivity = 0.7;
        newStatus = 'Noisy environment detected. Mic sensitivity reduced.';
      } else if (normalized < 0.05) {
        newSensitivity = 1.3;
        newStatus = 'Very quiet environment. Mic sensitivity increased.';
      } else {
        newSensitivity = 1.0;
        newStatus = 'Normal noise level. No adjustment needed.';
      }

      state = state.copyWith(
        noiseFloorLevel: normalized,
        noiseMeasured: true,
        isMeasuring: false,
        micSensitivity: newSensitivity,
        statusText: newStatus,
      );
    } catch (e) {
      await recorder.dispose();
      state = state.copyWith(isMeasuring: false, statusText: 'Measurement failed: $e');
    }
  }

  Future<bool> save() async {
    final calibration = CalibrationProfile(
      scoreOffset: state.scoreOffset,
      micSensitivity: state.micSensitivity,
      noiseFloorLevel: state.noiseFloorLevel,
      calibratedAt: DateTime.now(),
    );
    await ref.read(settingsNotifierProvider.notifier).setCalibration(calibration);
    return true;
  }

  void reset() {
    ref.read(settingsNotifierProvider.notifier).resetCalibration();
    state = const CalibrationState(statusText: 'Calibration reset to defaults.');
  }
}

// ─── Provider ───────────────────────────────────────────────────────────────

final calibrationNotifierProvider =
    NotifierProvider<CalibrationNotifier, CalibrationState>(CalibrationNotifier.new);
