import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:outcall/core/theme/app_colors.dart';
import 'package:outcall/core/widgets/background_wrapper.dart';
import 'package:outcall/features/settings/presentation/controllers/calibration_controller.dart';

/// Guided on-device calibration screen.
///
/// Allows users to:
/// 1. Measure ambient noise floor via a short recording
/// 2. Adjust score offset (±20 points)
/// 3. Adjust mic sensitivity multiplier (0.5x–2.0x)
class CalibrationScreen extends ConsumerWidget {
  const CalibrationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = AppColors.of(context);
    final primary = Theme.of(context).primaryColor;
    final cal = ref.watch(calibrationNotifierProvider);
    final notifier = ref.read(calibrationNotifierProvider.notifier);

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
                    Flexible(
                      child: Text(
                        'CALIBRATE SCORING',
                        style: GoogleFonts.oswald(
                          color: colors.textPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
                          onPressed: cal.isMeasuring ? null : () => notifier.measureNoiseFloor(),
                          icon: cal.isMeasuring
                              ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: colors.textPrimary))
                              : const Icon(Icons.mic, size: 20),
                          label: Text(cal.isMeasuring ? 'Measuring...' : (cal.noiseMeasured ? 'Re-measure' : 'Start Noise Test')),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      if (cal.statusText.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Center(
                          child: Text(
                            cal.statusText,
                            style: GoogleFonts.lato(color: primary, fontSize: 13, fontWeight: FontWeight.w500),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                      if (cal.noiseMeasured) ...[
                        const SizedBox(height: 8),
                        Center(
                          child: Text(
                            'Noise floor: ${(cal.noiseFloorLevel * 100).toStringAsFixed(0)}%',
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
                              value: cal.scoreOffset,
                              min: -20,
                              max: 20,
                              divisions: 40,
                              activeColor: primary,
                              inactiveColor: colors.border,
                              label: cal.scoreOffset.toStringAsFixed(0),
                              onChanged: (v) => notifier.setScoreOffset(v),
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
                            cal.scoreOffset >= 0
                                ? '+${cal.scoreOffset.toStringAsFixed(0)} points'
                                : '${cal.scoreOffset.toStringAsFixed(0)} points',
                            style: GoogleFonts.oswald(
                              color: cal.scoreOffset == 0
                                  ? colors.textSecondary
                                  : (cal.scoreOffset > 0 ? Colors.green : Colors.redAccent),
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
                              value: cal.micSensitivity,
                              min: 0.5,
                              max: 2.0,
                              divisions: 30,
                              activeColor: primary,
                              inactiveColor: colors.border,
                              label: '${cal.micSensitivity.toStringAsFixed(1)}x',
                              onChanged: (v) => notifier.setMicSensitivity(v),
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
                            '${cal.micSensitivity.toStringAsFixed(1)}x',
                            style: GoogleFonts.oswald(
                              color: cal.micSensitivity == 1.0
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
                            onPressed: () => notifier.reset(),
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
                            onPressed: () async {
                              await notifier.save();
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Calibration saved!')),
                                );
                                Navigator.pop(context);
                              }
                            },
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
