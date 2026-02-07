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
    // Optimize spacing calculation
    final double spacing = size.width / (amplitudes.length > 50 ? amplitudes.length : 50);
    final double barWidth = spacing * 0.7;

    // Set baseline style once
    _baselinePaint.color = isRecording ? Colors.white24 : Colors.white10;
    
    // Create a path for all bars to draw in fewer calls
    final Path barPath = Path();
    
    // Pre-calculate common values
    final double maxBarHeight = size.height - 24;

    for (int i = 0; i < amplitudes.length; i++) {
        final double x = i * spacing + (barWidth / 2);
        
        // Skip bars that are outside visible width
        if (x > size.width) break;

        final double amp = amplitudes[i];
        if (amp < 0.01) continue; // Skip near-silent bars
        
        final double barHeight = (amp.clamp(0.0, 1.0) * maxBarHeight) + 4;
        
        final rect = Rect.fromCenter(
            center: Offset(x, centerY),
            width: barWidth,
            height: barHeight,
        );
        
        barPath.addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(2)));
    }

    // Use a single color or simple gradient instead of per-bar color
    if (isRecording) {
        _barPaint.color = color;
        // Optional: specific shader could go here for gradient across the whole visualizer 
        // but solid color is fastest and cleanest for "Pro" look
    } else {
        _barPaint.color = Colors.white10;
    }

    // One draw call for all bars
    canvas.drawPath(barPath, _barPaint);

    // Draw baseline
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
