import 'package:flutter/material.dart';

class LiveVisualizer extends StatelessWidget {
  final List<double> amplitudes;
  final Color color;
  final bool isRecording;

  const LiveVisualizer({
    super.key,
    required this.amplitudes,
    this.color = Colors.green,
    this.isRecording = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      width: double.infinity,
      child: CustomPaint(
        painter: _VisualizerPainter(
          amplitudes: amplitudes,
          color: color,
          isRecording: isRecording,
        ),
      ),
    );
  }
}

class _VisualizerPainter extends CustomPainter {
  final List<double> amplitudes;
  final Color color;
  final bool isRecording;

  _VisualizerPainter({
    required this.amplitudes,
    required this.color,
    required this.isRecording,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (amplitudes.isEmpty) return;

    final double centerY = size.height / 2;
    final double spacing = size.width / 50;
    final double barWidth = spacing * 0.7;

    for (int i = 0; i < amplitudes.length; i++) {
      final double x = i * spacing + (barWidth / 2);
      final double amp = amplitudes[i].clamp(0.0, 1.0);
      
      final double barHeight = (amp * (size.height - 20)) + 4;
      
      // Dynamic color based on amplitude
      final Color barColor = isRecording 
          ? Color.lerp(Colors.greenAccent, Colors.orangeAccent, amp) ?? color
          : Colors.white24;

      final paint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            barColor.withValues(alpha: 0.7),
            barColor,
            barColor.withValues(alpha: 0.7),
          ],
        ).createShader(Rect.fromCenter(
          center: Offset(x, centerY),
          width: barWidth,
          height: barHeight,
        ))
        ..style = PaintingStyle.fill;

      // Add a subtle glow if recording and amplitude is significant
      if (isRecording && amp > 0.2) {
        final shadowPaint = Paint()
          ..color = barColor.withValues(alpha: 0.3)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, amp * 10);
        
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset(x, centerY),
              width: barWidth + 2,
              height: barHeight + 2,
            ),
            const Radius.circular(4),
          ),
          shadowPaint,
        );
      }

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(x, centerY),
            width: barWidth,
            height: barHeight,
          ),
          const Radius.circular(4),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _VisualizerPainter oldDelegate) {
    return oldDelegate.amplitudes != amplitudes || 
           oldDelegate.isRecording != isRecording;
  }
}
