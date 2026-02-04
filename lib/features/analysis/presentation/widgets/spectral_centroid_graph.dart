import 'package:flutter/material.dart';
import 'dart:ui' as ui;

class SpectralCentroidGraph extends StatelessWidget {
  final List<double> centroids;
  final double height;
  final Color color;

  const SpectralCentroidGraph({
    super.key,
    required this.centroids,
    this.height = 100,
    this.color = Colors.lightBlueAccent,
  });

  @override
  Widget build(BuildContext context) {
    if (centroids.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: CustomPaint(
        painter: _CentroidPainter(centroids, color),
      ),
    );
  }
}

class _CentroidPainter extends CustomPainter {
  final List<double> centroids;
  final Color color;

  _CentroidPainter(this.centroids, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    if (centroids.isEmpty) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.3)
      ..strokeWidth = 4.0
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    final path = Path();
    final stepX = size.width / (centroids.length - 1);
    
    // Normalize centroids for display (expecting values in Hz)
    const maxFreq = 4000.0; // Assume 4kHz as reasonable max for centroid visualization
    
    for (var i = 0; i < centroids.length; i++) {
      final x = i * stepX;
      final y = size.height - (centroids[i] / maxFreq * size.height).clamp(0, size.height);
      
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, glowPaint);
    canvas.drawPath(path, paint);

    // Fill area under the curve
    final fillPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    final gradient = ui.Gradient.linear(
      Offset(0, 0),
      Offset(0, size.height),
      [color.withValues(alpha: 0.4), color.withValues(alpha: 0.0)],
    );

    canvas.drawPath(fillPath, Paint()..shader = gradient);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
