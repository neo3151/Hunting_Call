import 'dart:math' as math;
import 'package:flutter/material.dart';

class WindCompass extends StatelessWidget {
  final double windDegree; // 0 is North, 90 is East, etc.
  final double windSpeed;

  const WindCompass({
    super.key,
    required this.windDegree,
    required this.windSpeed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: 200,
          height: 200,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer circle
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white24, width: 2),
                ),
              ),
              // Cardinal directions
              const _CardinalLabels(),
              // Scent Cone and Arrow
              CustomPaint(
                size: const Size(200, 200),
                painter: _WindPainter(windDegree: windDegree, windSpeed: windSpeed),
              ),
              // Center Hunter Icon
              const Icon(Icons.person, color: Colors.white, size: 30),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'WIND: ${windSpeed.toStringAsFixed(1)} MPH',
          style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

class _CardinalLabels extends StatelessWidget {
  const _CardinalLabels();

  @override
  Widget build(BuildContext context) {
    return const Stack(
      children: [
        Align(alignment: Alignment.topCenter, child: Padding(padding: EdgeInsets.only(top: 8), child: Text('N', style: TextStyle(color: Colors.white70)))),
        Align(alignment: Alignment.bottomCenter, child: Padding(padding: EdgeInsets.only(bottom: 8), child: Text('S', style: TextStyle(color: Colors.white70)))),
        Align(alignment: Alignment.centerLeft, child: Padding(padding: EdgeInsets.only(left: 8), child: Text('W', style: TextStyle(color: Colors.white70)))),
        Align(alignment: Alignment.centerRight, child: Padding(padding: EdgeInsets.only(right: 8), child: Text('E', style: TextStyle(color: Colors.white70)))),
      ],
    );
  }
}

class _WindPainter extends CustomPainter {
  final double windDegree;
  final double windSpeed;

  _WindPainter({required this.windDegree, required this.windSpeed});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    
    // Convert degrees to radians (Flutter's 0 is right, compass 0 is top)
    final angle = (windDegree - 90) * (math.pi / 180);
    
    // Draw Scent Cone (Behind arrow)
    final conePaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.orange.withValues(alpha: 0.4),
          Colors.orange.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.fill;

    // The scent blows AWAY from the wind direction
    final flowAngle = angle + math.pi;
    const spread = 0.5; // radians

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius * 0.9),
      flowAngle - spread,
      spread * 2,
      true,
      conePaint,
    );

    // Draw Wind Arrow
    final arrowPaint = Paint()
      ..color = Colors.orangeAccent
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final arrowEnd = Offset(
      center.dx + radius * 0.7 * math.cos(angle),
      center.dy + radius * 0.7 * math.sin(angle),
    );

    canvas.drawLine(center, arrowEnd, arrowPaint);
    
    // Draw Arrowhead pointing TOWARDS center (where wind is coming FROM)
    // Actually, usually arrow points WHERE wind is blowing.
    // Let's make it point WHERE IT'S BLOWING.
    
    final path = Path();
    const headSize = 10.0;
    path.moveTo(arrowEnd.dx, arrowEnd.dy);
    path.lineTo(
      arrowEnd.dx - headSize * math.cos(angle - 0.5),
      arrowEnd.dy - headSize * math.sin(angle - 0.5),
    );
    path.lineTo(
      arrowEnd.dx - headSize * math.cos(angle + 0.5),
      arrowEnd.dy - headSize * math.sin(angle + 0.5),
    );
    path.close();
    
    final fillPaint = Paint()..color = Colors.orangeAccent..style = PaintingStyle.fill;
    canvas.drawPath(path, fillPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
