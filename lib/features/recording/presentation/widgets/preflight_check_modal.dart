import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:outcall/core/theme/app_colors.dart';
import 'package:outcall/features/analysis/data/mic_calibration_service.dart';

class PreFlightCheckModal extends ConsumerStatefulWidget {
  const PreFlightCheckModal({super.key});

  @override
  ConsumerState<PreFlightCheckModal> createState() => _PreFlightCheckModalState();
}

class _PreFlightCheckModalState extends ConsumerState<PreFlightCheckModal> {
  bool _isCalibrating = true;
  bool _calibrationFailed = false;
  String _statusText = 'Analyzing Ambient Noise Floor...';
  CalibrationProfile? _profile;

  @override
  void initState() {
    super.initState();
    _runCalibration();
  }

  Future<void> _runCalibration() async {
    try {
      final service = ref.read(micCalibrationServiceProvider);
      final profile = await service.executePreFlightCheck();

      if (!mounted) return;

      setState(() {
        _profile = profile;
        _isCalibrating = false;
        if (profile.environmentalNoiseTooHigh) {
          _statusText = 'Calibration Failed: Environment Too Loud';
          _calibrationFailed = true;
        } else if (profile.requiresNoiseGating) {
          _statusText = 'Calibration Success: Noise Gating Active';
        } else {
          _statusText = 'Calibration Success: Optimal Studio Environment';
        }
      });

      // Auto-close on success after a brief delay
      if (!_calibrationFailed) {
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) Navigator.of(context).pop(true);
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isCalibrating = false;
        _calibrationFailed = true;
        _statusText = 'Hardware Error: Could not calibrate microphone.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.of(context).surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.of(context).border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 20,
              spreadRadius: 5,
            )
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'HARDWARE CALIBRATION',
              style: GoogleFonts.oswald(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: 2.0,
                color: AppColors.accentGold,
              ),
            ),
            const SizedBox(height: 24),
            if (_isCalibrating)
              const SizedBox(
                width: 48,
                height: 48,
                child: CircularProgressIndicator(color: Colors.orange),
              )
            else if (_calibrationFailed)
              const Icon(Icons.error_outline, color: Colors.redAccent, size: 48)
            else
              const Icon(Icons.check_circle_outline, color: Colors.greenAccent, size: 48),
            const SizedBox(height: 24),
            Text(
              _statusText,
              textAlign: TextAlign.center,
              style: GoogleFonts.lato(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppColors.of(context).textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            if (_isCalibrating)
              Text(
                'Please remain perfectly silent. Measuring DSP limits...',
                textAlign: TextAlign.center,
                style: GoogleFonts.lato(
                  fontSize: 14,
                  color: AppColors.of(context).textSubtle,
                ),
              ),
            if (_profile != null && _calibrationFailed) ...[
              Text(
                'Noise Floor: ${_profile!.noiseFloorDb.toStringAsFixed(1)} dB\n(Must be below -30dB)',
                textAlign: TextAlign.center,
                style: GoogleFonts.lato(
                  fontSize: 14,
                  color: AppColors.of(context).textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.of(context).cardOverlay,
                    foregroundColor: AppColors.of(context).textPrimary,
                  ),
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('ABORT SESSION'),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () {
                    // Force retry
                    setState(() {
                      _isCalibrating = true;
                      _calibrationFailed = false;
                      _statusText = 'Re-analyzing Ambient Noise Floor...';
                    });
                    _runCalibration();
                  },
                  child: Text('RETRY CALIBRATION', style: GoogleFonts.oswald(letterSpacing: 1.0)),
                ),
              ),
            ],
            if (_profile != null && !_calibrationFailed)
              Text(
                'Noise Floor: ${_profile!.noiseFloorDb.toStringAsFixed(1)} dB',
                textAlign: TextAlign.center,
                style: GoogleFonts.lato(
                  fontSize: 14,
                  color: AppColors.of(context).textSecondary,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Helper to show the check. Returns true if calibration passed.
Future<bool> showPreFlightCheck(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => const PreFlightCheckModal(),
  );
  return result ?? false;
}
