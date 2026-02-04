import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class WaveformOverlay extends StatelessWidget {
  final List<double> userWaveform;
  final List<double>? referenceWaveform;
  final double height;

  const WaveformOverlay({
    super.key,
    required this.userWaveform,
    this.referenceWaveform,
    this.height = 120, // Slightly taller
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height + 90,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7), // Darker background for better contrast
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("SPECTRAL SYNC", 
                    style: GoogleFonts.oswald(
                      fontSize: 14, 
                      letterSpacing: 3.0, 
                      color: const Color(0xFF5FF7B6), 
                      fontWeight: FontWeight.bold
                    )
                  ),
                  Text("COMPARING YOUR CALL TO THE IDEAL PATTERN",
                    style: GoogleFonts.oswald(
                      fontSize: 8,
                      letterSpacing: 1.0,
                      color: Colors.white38,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  _buildLegendItem("REF", Colors.white.withOpacity(0.4)),
                  const SizedBox(width: 16),
                  _buildLegendItem("YOU", const Color(0xFF5FF7B6)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: _buildAlignedWaveform(),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12, 
          height: 12, 
          decoration: BoxDecoration(
            color: color, 
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: Colors.white24, width: 0.5),
          )
        ),
        const SizedBox(width: 6),
        Text(label, 
          style: GoogleFonts.oswald(
            fontSize: 10, 
            color: Colors.white, 
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          )
        ),
      ],
    );
  }

  Widget _buildAlignedWaveform() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        // Use 80 points for thicker bars
        const dataPoints = 80;
        final barGap = 2.0;
        final barWidth = (width - (dataPoints - 1) * barGap) / dataPoints;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(dataPoints, (index) {
            // Map the 100 points from analyzer to 80 points for display
            final sourceIdx = (index * (userWaveform.length / dataPoints)).floor();
            
            final userVal = (userWaveform.length > sourceIdx) ? userWaveform[sourceIdx] : 0.0;
            final refVal = (referenceWaveform != null && referenceWaveform!.length > sourceIdx) 
                ? referenceWaveform![sourceIdx] 
                : 0.0;

            return SizedBox(
              width: barWidth,
              height: height,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Reference Bar (Background / Ghost)
                  // Using a more visible "ghost" color - light grey with white border
                  if (referenceWaveform != null)
                    Container(
                      width: barWidth,
                      height: (refVal * height).clamp(2.0, height),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(barWidth / 2),
                        border: Border.all(color: Colors.white.withOpacity(0.1), width: 0.5),
                      ),
                    ),
                  // User Bar (Foreground / Active)
                  Container(
                    width: barWidth * 0.6,
                    height: (userVal * height).clamp(2.0, height),
                    decoration: BoxDecoration(
                      color: const Color(0xFF5FF7B6),
                      borderRadius: BorderRadius.circular(barWidth / 4),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF5FF7B6).withOpacity(0.4),
                          blurRadius: 6,
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        );
      },
    );
  }
}
