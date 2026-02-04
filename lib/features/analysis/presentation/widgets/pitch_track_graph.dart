import 'package:flutter/material.dart';

class PitchTrackGraph extends StatelessWidget {
  final List<double> pitchTrack;
  final double height;
  final Color color;

  const PitchTrackGraph({
    super.key,
    required this.pitchTrack,
    this.height = 100,
    this.color = Colors.orangeAccent,
  });

  @override
  Widget build(BuildContext context) {
    if (pitchTrack.isEmpty) {
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
        painter: _PitchPainter(pitchTrack, color),
      ),
    );
  }
}

class _PitchPainter extends CustomPainter {
  final List<double> pitchTrack;
  final Color color;

  _PitchPainter(this.pitchTrack, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    if (pitchTrack.isEmpty) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final stepX = size.width / (pitchTrack.length - 1);
    
    // Normalize pitch for display
    // Find min/max for better resolution
    double minPitch = pitchTrack.reduce((a, b) => a < b ? a : b);
    double maxPitch = pitchTrack.reduce((a, b) => a > b ? a : b);
    
    // Add some padding
    double range = maxPitch - minPitch;
    if (range < 10) range = 10;
    minPitch -= range * 0.1;
    maxPitch += range * 0.1;
    
    for (var i = 0; i < pitchTrack.length; i++) {
      final x = i * stepX;
      final y = size.height - ((pitchTrack[i] - minPitch) / (maxPitch - minPitch) * size.height);
      
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);

    // Draw dots at points
    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    for (var i = 0; i < pitchTrack.length; i++) {
      final x = i * stepX;
      final y = size.height - ((pitchTrack[i] - minPitch) / (maxPitch - minPitch) * size.height);
      canvas.drawCircle(Offset(x, y), 2.5, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
