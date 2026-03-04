import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:outcall/core/theme/app_colors.dart';
import 'package:outcall/core/widgets/background_wrapper.dart';
import 'package:outcall/features/settings/domain/calibration_profile.dart';
import 'package:outcall/features/settings/presentation/controllers/settings_controller.dart';
import 'package:record/record.dart';

/// Guided on-device calibration screen.
///
/// Allows users to:
/// 1. Measure ambient noise floor via a short recording
/// 2. Adjust score offset (±20 points)
/// 3. Adjust mic sensitivity multiplier (0.5x–2.0x)
class CalibrationScreen extends ConsumerStatefulWidget {
  const CalibrationScreen({super.key});

  @override
  ConsumerState<CalibrationScreen> createState() => _CalibrationScreenState();
}

class _CalibrationScreenState extends ConsumerState<CalibrationScreen> {
  double _scoreOffset = 0.0;
  double _micSensitivity = 1.0;
  double _noiseFloorLevel = 0.0;
  bool _isMeasuring = false;
  bool _noiseMeasured = false;
  String _statusText = '';

  @override
  void initState() {
    super.initState();
    // Load existing calibration
    final settingsAsync = ref.read(settingsNotifierProvider);
    final settings = settingsAsync.when(
      data: (s) => s,
      loading: () => null,
      error: (_, __) => null,
    );
    if (settings != null) {
      final cal = settings.calibration;
      _scoreOffset = cal.scoreOffset;
      _micSensitivity = cal.micSensitivity;
      _noiseFloorLevel = cal.noiseFloorLevel;
      _noiseMeasured = cal.isCalibrated;
    }
  }

  Future<void> _measureNoiseFloor() async {
    setState(() {
      _isMeasuring = true;
      _statusText = 'Recording ambient noise...';
    });

    final recorder = AudioRecorder();

    try {
      // Check permission
      if (!await recorder.hasPermission()) {
        setState(() {
          _isMeasuring = false;
          _statusText = 'Microphone permission denied.';
        });
        return;
      }

      // Start recording
      await recorder.start(
        const RecordConfig(encoder: AudioEncoder.wav, numChannels: 1, sampleRate: 44100),
        path: '${(await Directory.systemTemp.createTemp('cal_')).path}/noise_test.wav',
      );

      // Record for 3 seconds
      int remaining = 3;
      while (remaining > 0) {
        setState(() => _statusText = 'Keep quiet... ${remaining}s remaining');
        await Future.delayed(const Duration(seconds: 1));
        remaining--;
      }

      // Get amplitude
      final amplitude = await recorder.getAmplitude();
      await recorder.stop();
      await recorder.dispose();

      // Convert dBFS to a 0-1 scale (dBFS is negative; 0 = max, -60 = silence)
      final dBFS = amplitude.current;
      // Clamp to reasonable range
      final normalized = ((dBFS + 60) / 60).clamp(0.0, 1.0);

      setState(() {
        _noiseFloorLevel = normalized;
        _noiseMeasured = true;
        _isMeasuring = false;

        // Auto-suggest mic sensitivity based on noise floor
        if (normalized > 0.3) {
          _micSensitivity = 0.7; // Noisy environment, reduce sensitivity
          _statusText = 'Noisy environment detected. Mic sensitivity reduced.';
        } else if (normalized < 0.05) {
          _micSensitivity = 1.3; // Very quiet, boost a bit
          _statusText = 'Very quiet environment. Mic sensitivity increased.';
        } else {
          _micSensitivity = 1.0;
          _statusText = 'Normal noise level. No adjustment needed.';
        }
      });
    } catch (e) {
      await recorder.dispose();
      setState(() {
        _isMeasuring = false;
        _statusText = 'Measurement failed: $e';
      });
    }
  }

  Future<void> _save() async {
    final calibration = CalibrationProfile(
      scoreOffset: _scoreOffset,
      micSensitivity: _micSensitivity,
      noiseFloorLevel: _noiseFloorLevel,
      calibratedAt: DateTime.now(),
    );
    await ref.read(settingsNotifierProvider.notifier).setCalibration(calibration);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Calibration saved!')),
      );
      Navigator.pop(context);
    }
  }

  Future<void> _reset() async {
    await ref.read(settingsNotifierProvider.notifier).resetCalibration();
    setState(() {
      _scoreOffset = 0.0;
      _micSensitivity = 1.0;
      _noiseFloorLevel = 0.0;
      _noiseMeasured = false;
      _statusText = 'Calibration reset to defaults.';
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final primary = Theme.of(context).primaryColor;

    return Scaffold(
      body: BackgroundWrapper(
        child: SafeArea(
          child: Column(
            children: [
              // App bar
              Container(
                padding: const EdgeInsets.fromLTRB(8, 8, 16, 16),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back, color: colors.textPrimary),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'CALIBRATE SCORING',
                      style: GoogleFonts.oswald(
                        color: colors.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Introduction
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: primary.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, color: primary, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Adjust these settings if scores seem consistently too high or too low on your device.',
                                style: GoogleFonts.lato(
                                  color: colors.textSecondary,
                                  fontSize: 13,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),

                      // ─── Noise Floor Test ───────────────────────
                      _sectionTitle(context, 'AMBIENT NOISE TEST'),
                      const SizedBox(height: 8),
                      Text(
                        'Measure your environment\'s noise level to auto-tune mic sensitivity.',
                        style: GoogleFonts.lato(color: colors.textSubtle, fontSize: 13),
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: ElevatedButton.icon(
                          onPressed: _isMeasuring ? null : _measureNoiseFloor,
                          icon: _isMeasuring
                              ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: colors.textPrimary))
                              : const Icon(Icons.mic, size: 20),
                          label: Text(_isMeasuring ? 'Measuring...' : (_noiseMeasured ? 'Re-measure' : 'Start Noise Test')),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      if (_statusText.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Center(
                          child: Text(
                            _statusText,
                            style: GoogleFonts.lato(color: primary, fontSize: 13, fontWeight: FontWeight.w500),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                      if (_noiseMeasured) ...[
                        const SizedBox(height: 8),
                        Center(
                          child: Text(
                            'Noise floor: ${(_noiseFloorLevel * 100).toStringAsFixed(0)}%',
                            style: GoogleFonts.lato(color: colors.textTertiary, fontSize: 12),
                          ),
                        ),
                      ],
                      const SizedBox(height: 28),

                      // ─── Score Offset ───────────────────────────
                      _sectionTitle(context, 'SCORE OFFSET'),
                      const SizedBox(height: 8),
                      Text(
                        'Add or subtract points from your final score.',
                        style: GoogleFonts.lato(color: colors.textSubtle, fontSize: 13),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Text('-20', style: GoogleFonts.lato(color: colors.textTertiary, fontSize: 12)),
                          Expanded(
                            child: Slider(
                              value: _scoreOffset,
                              min: -20,
                              max: 20,
                              divisions: 40,
                              activeColor: primary,
                              inactiveColor: colors.border,
                              label: _scoreOffset.toStringAsFixed(0),
                              onChanged: (v) => setState(() => _scoreOffset = v),
                            ),
                          ),
                          Text('+20', style: GoogleFonts.lato(color: colors.textTertiary, fontSize: 12)),
                        ],
                      ),
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            color: colors.cardOverlay,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _scoreOffset >= 0
                                ? '+${_scoreOffset.toStringAsFixed(0)} points'
                                : '${_scoreOffset.toStringAsFixed(0)} points',
                            style: GoogleFonts.oswald(
                              color: _scoreOffset == 0
                                  ? colors.textSecondary
                                  : (_scoreOffset > 0 ? Colors.green : Colors.redAccent),
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),

                      // ─── Mic Sensitivity ────────────────────────
                      _sectionTitle(context, 'MIC SENSITIVITY'),
                      const SizedBox(height: 8),
                      Text(
                        'Adjust how sensitive the volume readings are to your microphone.',
                        style: GoogleFonts.lato(color: colors.textSubtle, fontSize: 13),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Text('0.5x', style: GoogleFonts.lato(color: colors.textTertiary, fontSize: 12)),
                          Expanded(
                            child: Slider(
                              value: _micSensitivity,
                              min: 0.5,
                              max: 2.0,
                              divisions: 30,
                              activeColor: primary,
                              inactiveColor: colors.border,
                              label: '${_micSensitivity.toStringAsFixed(1)}x',
                              onChanged: (v) => setState(() => _micSensitivity = v),
                            ),
                          ),
                          Text('2.0x', style: GoogleFonts.lato(color: colors.textTertiary, fontSize: 12)),
                        ],
                      ),
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            color: colors.cardOverlay,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${_micSensitivity.toStringAsFixed(1)}x',
                            style: GoogleFonts.oswald(
                              color: _micSensitivity == 1.0
                                  ? colors.textSecondary
                                  : primary,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 36),

                      // ─── Action Buttons ─────────────────────────
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          OutlinedButton.icon(
                            onPressed: _reset,
                            icon: const Icon(Icons.restore, size: 18),
                            label: const Text('Reset'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: colors.textTertiary,
                              side: BorderSide(color: colors.border),
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                          const SizedBox(width: 16),
                          ElevatedButton.icon(
                            onPressed: _save,
                            icon: const Icon(Icons.check, size: 18),
                            label: const Text('Save'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 4),
      child: Text(
        title,
        style: GoogleFonts.oswald(
          color: Theme.of(context).primaryColor,
          fontSize: 14,
          fontWeight: FontWeight.bold,
          letterSpacing: 2.0,
        ),
      ),
    );
  }
}
