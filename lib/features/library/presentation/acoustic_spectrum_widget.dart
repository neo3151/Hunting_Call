import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AcousticSpectrumWidget extends StatelessWidget {
  final double pitchHz;
  final double durationSec;

  const AcousticSpectrumWidget({
    super.key,
    required this.pitchHz,
    required this.durationSec,
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
          Text(
            "BIOACOUSTIC SPECTRUM",
            style: GoogleFonts.oswald(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 20),
          _buildSpectrumRow(
            label: "FREQUENCY",
            value: "${pitchHz.toInt()} Hz",
            percentage: (pitchHz / 5000).clamp(0.0, 1.0), // Cap at 5kHz for visualization
            color: const Color(0xFF64B5F6),
            minLabel: "Low (Bass)",
            maxLabel: "High (Treble)",
            icon: Icons.graphic_eq,
          ),
          const SizedBox(height: 24),
          _buildSpectrumRow(
            label: "DURATION",
            value: "${durationSec.toStringAsFixed(1)} s",
            percentage: (durationSec / 10.0).clamp(0.0, 1.0), // Cap at 10s
            color: const Color(0xFFFFB74D),
            minLabel: "Short",
            maxLabel: "Sustained",
            icon: Icons.timer,
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
        Stack(
          children: [
            // Background Track
            Container(
              height: 12,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            // Gradient Fill
            LayoutBuilder(
              builder: (context, constraints) {
                return Container(
                  height: 12,
                  width: constraints.maxWidth * percentage,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [color.withValues(alpha: 0.5), color]),
                    borderRadius: BorderRadius.circular(6),
                  ),
                );
              },
            ),
            // Marker
            LayoutBuilder(
              builder: (context, constraints) {
                return Padding(
                  padding: EdgeInsets.only(left: (constraints.maxWidth * percentage).clamp(0.0, constraints.maxWidth - 4) - 2), // Adjust for marker width
                  child: Container(
                    height: 12,
                    width: 4,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              },
            ),
          ],
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
