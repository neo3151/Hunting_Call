import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class WaveformOverlay extends StatelessWidget {
  final List<double> userWaveform;
  final List<double>? referenceWaveform;
  final double height;
  final VoidCallback? onPlayUser;
  final VoidCallback? onPlayReference;
  final bool isUserPlaying;
  final bool isReferencePlaying;

  const WaveformOverlay({
    super.key,
    required this.userWaveform,
    this.referenceWaveform,
    this.height = 120,
    this.onPlayUser,
    this.onPlayReference,
    this.isUserPlaying = false,
    this.isReferencePlaying = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      // Height increased to accommodate buttons
      height: height + 160,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5FF7B6).withValues(alpha: 0.05),
            blurRadius: 20,
            spreadRadius: 2,
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
                      letterSpacing: 1.5, 
                      color: const Color(0xFF5FF7B6), 
                      fontWeight: FontWeight.bold
                    )
                  ),
                  Text("WAVEFORM COMPARISON",
                    style: GoogleFonts.oswald(
                      fontSize: 8,
                      letterSpacing: 1.0,
                      color: Colors.white38,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    _buildLegendItem("REF", Colors.white.withValues(alpha: 0.3)),
                    const SizedBox(width: 8),
                    _buildLegendItem("YOU", const Color(0xFF5FF7B6)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: _buildAlignedWaveform(),
          ),
          const SizedBox(height: 24),
          // Playback Buttons
          Row(
            children: [
              Expanded(
                child: _buildPlaybackButton(
                  label: "PLAY YOURS",
                  icon: isUserPlaying ? Icons.stop_rounded : Icons.play_arrow_rounded,
                  color: const Color(0xFF5FF7B6),
                  onPressed: onPlayUser,
                  isSelected: isUserPlaying,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildPlaybackButton(
                  label: "PLAY REF",
                  icon: isReferencePlaying ? Icons.stop_rounded : Icons.play_arrow_rounded,
                  color: Colors.white.withValues(alpha: 0.8),
                  onPressed: onPlayReference,
                  isSelected: isReferencePlaying,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlaybackButton({
    required String label, 
    required IconData icon, 
    required Color color, 
    VoidCallback? onPressed,
    required bool isSelected,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? color.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: isSelected ? color : Colors.white70, size: 16),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.oswald(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                  color: isSelected ? color : Colors.white70,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 8, 
          height: 8, 
          decoration: BoxDecoration(
            color: color, 
            shape: BoxShape.circle,
          )
        ),
        const SizedBox(width: 6),
        Text(label, 
          style: GoogleFonts.oswald(
            fontSize: 9, 
            color: Colors.white70, 
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          )
        ),
      ],
    );
  }

  Widget _buildAlignedWaveform() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 1200),
          curve: Curves.easeOutCubic,
          tween: Tween(begin: 0.0, end: 1.0),
          builder: (context, anim, child) {
            return CustomPaint(
              size: Size(constraints.maxWidth, height),
              painter: _WaveformPainter(
                userWaveform: userWaveform,
                referenceWaveform: referenceWaveform,
                animationValue: anim,
                userColor: const Color(0xFF5FF7B6),
                refColor: Colors.white.withValues(alpha: 0.15),
              ),
            );
          },
        );
      },
    );
  }
}

class _WaveformPainter extends CustomPainter {
  final List<double> userWaveform;
  final List<double>? referenceWaveform;
  final double animationValue;
  final Color userColor;
  final Color refColor;

  _WaveformPainter({
    required this.userWaveform,
    this.referenceWaveform,
    required this.animationValue,
    required this.userColor,
    required this.refColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const dataPoints = 60;
    final barGap = size.width / (dataPoints * 3);
    final barWidth = (size.width - (dataPoints - 1) * barGap) / dataPoints;
    final centerY = size.height / 2;

    final paint = Paint()..style = PaintingStyle.fill;
    final userPaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [userColor, userColor.withValues(alpha: 0.7)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    for (int i = 0; i < dataPoints; i++) {
      final sourceIdx = (i * (userWaveform.length / dataPoints)).floor();
      final userVal = (userWaveform.length > sourceIdx) ? userWaveform[sourceIdx] : 0.0;
      final x = i * (barWidth + barGap);

      // 1. Draw Reference
      if (referenceWaveform != null) {
        final refVal = (referenceWaveform!.length > sourceIdx) ? referenceWaveform![sourceIdx] : 0.0;
        final refH = refVal * size.height * animationValue;
        
        paint.color = refColor;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(x + barWidth/2, centerY), width: barWidth, height: refH.clamp(2, size.height)),
            Radius.circular(barWidth / 2),
          ),
          paint,
        );
      }

      // 2. Draw User
      final userH = userVal * size.height * animationValue;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(x + barWidth/2, centerY), width: barWidth * 0.7, height: userH.clamp(2, size.height)),
          Radius.circular(barWidth / 4),
        ),
        userPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WaveformPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue || 
           oldDelegate.userWaveform != userWaveform || 
           oldDelegate.referenceWaveform != referenceWaveform;
  }
}
