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
    return RepaintBoundary(
      child: SizedBox(
        height: 120,
        width: double.infinity,
        child: CustomPaint(
          painter: _VisualizerPainter(
            amplitudes: amplitudes,
            color: color,
            isRecording: isRecording,
          ),
        ),
      ),
    );
  }
}

class _VisualizerPainter extends CustomPainter {
  final List<double> amplitudes;
  final Color color;
  final bool isRecording;

  // Reuse paint objects to reduce garbage collection pressure
  final _barPaint = Paint()..style = PaintingStyle.fill;
  final _shadowPaint = Paint()..style = PaintingStyle.fill;
  final _baselinePaint = Paint()..strokeWidth = 1..style = PaintingStyle.stroke;

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

    _baselinePaint.color = isRecording ? Colors.white24 : Colors.white10;

    for (int i = 0; i < amplitudes.length; i++) {
      final double x = i * spacing + (barWidth / 2);
      final double amp = amplitudes[i].clamp(0.0, 1.0);
      
      final double barHeight = (amp * (size.height - 24)) + 4;
      
      // Dynamic color based on amplitude
      final Color barColor = isRecording 
          ? Color.lerp(const Color(0xFF81C784), const Color(0xFF64FFDA), amp) ?? color
          : Colors.white10;

      final barRect = Rect.fromCenter(
        center: Offset(x, centerY),
        width: barWidth,
        height: barHeight,
      );

      // Add a subtle glow if recording and amplitude is significant
      if (isRecording && amp > 0.1) {
        _shadowPaint
          ..color = barColor.withValues(alpha: 0.15 * amp)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, amp * 8);
        
        canvas.drawRect(barRect.inflate(1), _shadowPaint);
      }

      // Draw the bar with a simpler gradient or solid color to save GPU cycles
      _barPaint.color = barColor;
      // Note: Full gradient per bar is expensive, we use barColor directly or a global shader
      
      canvas.drawRRect(
        RRect.fromRectAndRadius(barRect, const Radius.circular(2)),
        _barPaint,
      );
    }

    // Draw a subtle baseline across the center
    canvas.drawLine(
      Offset(0, centerY),
      Offset(size.width, centerY),
      _baselinePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _VisualizerPainter oldDelegate) {
    return oldDelegate.amplitudes != amplitudes || 
           oldDelegate.isRecording != isRecording;
  }
}
