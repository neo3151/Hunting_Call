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

    final paint = Paint()
      ..color = isRecording ? color : color.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill
      ..strokeCap = StrokeCap.round;

    final double centerY = size.height / 2;
    final double spacing = size.width / 50; // Match the 50 points we keep
    final double barWidth = spacing * 0.6;

    for (int i = 0; i < amplitudes.length; i++) {
      final double x = i * spacing + (barWidth / 2);
      final double amp = amplitudes[i];
      
      // Calculate height with a minimum of 4 pixels for aesthetics
      final double barHeight = (amp * (size.height - 20)) + 4;
      
      // Draw mirrored bars
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(x, centerY),
            width: barWidth,
            height: barHeight,
          ),
          const Radius.circular(5),
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
