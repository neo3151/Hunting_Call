import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Glassmorphic metric card for audio analytics display.
class AnalyticsMetricCard extends StatelessWidget {
  final String label;
  final double value;
  final String unit;

  const AnalyticsMetricCard({
    super.key,
    required this.label,
    required this.value,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    final color = _getColorForValue(value, unit);

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          width: 160,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.lato(
                  color: Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _formatValue(value),
                    style: GoogleFonts.oswald(
                      color: color,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (unit.isNotEmpty) ...[
                    const SizedBox(width: 4),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Text(
                        unit,
                        style: GoogleFonts.lato(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: _normalizeForProgress(value, unit),
                  minHeight: 4,
                  backgroundColor: Colors.white.withValues(alpha: 0.1),
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Color _getColorForValue(double value, String unit) {
    if (unit == '%') {
      if (value >= 80) return Colors.greenAccent;
      if (value >= 60) return Colors.lightGreenAccent;
      if (value >= 40) return Colors.orangeAccent;
      return Colors.redAccent;
    }
    return Colors.greenAccent;
  }

  static double _normalizeForProgress(double value, String unit) {
    if (unit == '%') return value / 100;
    if (unit == 'Hz') return (value / 2000).clamp(0.0, 1.0);
    if (unit == 's') return (value / 5).clamp(0.0, 1.0);
    if (unit == 'BPM') return (value / 120).clamp(0.0, 1.0);
    return 0.5;
  }

  static String _formatValue(double value) {
    if (value >= 100) return value.toStringAsFixed(0);
    if (value >= 10) return value.toStringAsFixed(1);
    return value.toStringAsFixed(2);
  }
}
