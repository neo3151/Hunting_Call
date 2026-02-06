import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AcousticSpectrumWidget extends StatelessWidget {
  final double pitchHz;
  final double durationSec;
  final double? harmonicPurity; // New metric

  const AcousticSpectrumWidget({
    super.key,
    required this.pitchHz,
    required this.durationSec,
    this.harmonicPurity,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "BIOACOUSTIC SPECTRUM",
                style: GoogleFonts.oswald(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
              const Icon(Icons.analytics_outlined, color: Colors.white24, size: 16),
            ],
          ),
          const SizedBox(height: 20),
          _buildSpectrumRow(
            label: "FREQUENCY",
            value: "${pitchHz.toInt()} Hz",
            percentage: (pitchHz / 5000).clamp(0.0, 1.0),
            color: const Color(0xFF64B5F6),
            minLabel: "Low",
            maxLabel: "High",
            icon: Icons.graphic_eq,
            delayMs: 0,
          ),
          const SizedBox(height: 24),
          _buildSpectrumRow(
            label: "DURATION",
            value: "${durationSec.toStringAsFixed(1)} s",
            percentage: (durationSec / 10.0).clamp(0.0, 1.0),
            color: const Color(0xFFFFB74D),
            minLabel: "Short",
            maxLabel: "Long",
            icon: Icons.timer,
            delayMs: 200,
          ),
          const SizedBox(height: 24),
          _buildSpectrumRow(
            label: "HARMONIC PURITY",
            value: "${((harmonicPurity ?? 0.85) * 100).toInt()}%",
            percentage: (harmonicPurity ?? 0.85).clamp(0.0, 1.0),
            color: const Color(0xFF5FF7B6),
            minLabel: "Noisy",
            maxLabel: "Pure",
            icon: Icons.waves,
            delayMs: 400,
          ),
        ],
      ),
    );
  }

  Widget _buildSpectrumRow({
    required String label,
    required String value,
    required double percentage,
    required Color color,
    required String minLabel,
    required String maxLabel,
    required IconData icon,
    required int delayMs,
  }) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, size: 14, color: Colors.white54),
                const SizedBox(width: 8),
                Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold)),
              ],
            ),
            Text(value, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 8),
        TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 1000),
          curve: Curves.easeOutQuart,
          tween: Tween(begin: 0.0, end: percentage),
          builder: (context, animValue, child) {
            return SizedBox(
              height: 12,
              width: double.infinity,
              child: Stack(
                children: [
                  // Background Track
                  Container(
                    height: 12,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  // Gradient Fill
                  FractionallySizedBox(
                    widthFactor: animValue,
                    child: Container(
                      height: 12,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [color.withValues(alpha: 0.3), color]),
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: [
                            BoxShadow(
                                color: color.withValues(alpha: 0.2),
                                blurRadius: 8,
                                spreadRadius: 1,
                            )
                        ]
                      ),
                    ),
                  ),
                  // Marker
                  Align(
                    alignment: Alignment(animValue * 2 - 1, 0),
                    child: Container(
                      height: 12,
                      width: 4,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(minLabel, style: const TextStyle(color: Colors.white24, fontSize: 10)),
            Text(maxLabel, style: const TextStyle(color: Colors.white24, fontSize: 10)),
          ],
        ),
      ],
    );
  }
}
