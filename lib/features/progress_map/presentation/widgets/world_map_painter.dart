import 'dart:math';
import 'package:flutter/material.dart';
import 'package:outcall/features/progress_map/domain/world_info.dart';

/// Custom painter that renders the world map background, decorations,
/// path connections, and ambient particles.
class WorldMapPainter extends CustomPainter {
  final List<MapNode> nodes;
  final WorldInfo world;
  final double pulseValue;
  final double glowValue;
  final double particleValue;

  WorldMapPainter({
    required this.nodes,
    required this.world,
    required this.pulseValue,
    required this.glowValue,
    required this.particleValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _drawBackground(canvas, size);
    _drawGroundPatches(canvas, size);
    _drawDecorations(canvas, size);
    if (nodes.length >= 2) _drawPath(canvas, size);
    _drawParticles(canvas, size);
  }

  void _drawBackground(Canvas canvas, Size size) {
    final bgPaint = Paint()
      ..shader = LinearGradient(
        colors: [world.bgColorTop, world.bgColorBot, world.bgColorTop.withValues(alpha: 0.8)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        stops: const [0.0, 0.6, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.015)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    for (double y = 0; y < size.height; y += 40) {
      for (double x = 0; x < size.width; x += 35) {
        final offset = (y ~/ 40).isOdd ? 17.5 : 0.0;
        _drawHex(canvas, Offset(x + offset, y), 12, gridPaint);
      }
    }

    final vigPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.transparent,
          Colors.black.withValues(alpha: 0.4),
        ],
        stops: const [0.5, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), vigPaint);
  }

  void _drawHex(Canvas canvas, Offset center, double r, Paint paint) {
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final angle = (60 * i - 30) * pi / 180;
      final p = Offset(center.dx + r * cos(angle), center.dy + r * sin(angle));
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawGroundPatches(Canvas canvas, Size size) {
    final rng = Random(world.name.hashCode + 42);
    final paint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < 12; i++) {
      final cx = rng.nextDouble() * size.width;
      final cy = rng.nextDouble() * size.height;

      bool tooClose = false;
      for (final n in nodes) {
        final nx = n.position.dx * size.width;
        final ny = n.position.dy * size.height;
        if ((cx - nx).abs() < 60 && (cy - ny).abs() < 60) {
          tooClose = true;
          break;
        }
      }
      if (tooClose) continue;

      paint.color = world.groundColors[rng.nextInt(world.groundColors.length)]
          .withValues(alpha: 0.08 + rng.nextDouble() * 0.12);

      final w = 30.0 + rng.nextDouble() * 60;
      final h = 20.0 + rng.nextDouble() * 40;

      canvas.save();
      canvas.translate(cx, cy);
      canvas.rotate(rng.nextDouble() * 0.3);
      canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: w, height: h),
        paint,
      );
      canvas.restore();
    }
  }

  void _drawDecorations(Canvas canvas, Size size) {
    final rng = Random(world.name.hashCode + 99);

    // Large trees
    for (int i = 0; i < 18; i++) {
      final tx = rng.nextDouble() * size.width;
      final ty = rng.nextDouble() * size.height;

      bool tooClose = false;
      for (final n in nodes) {
        final nx = n.position.dx * size.width;
        final ny = n.position.dy * size.height;
        if ((tx - nx).abs() < 55 && (ty - ny).abs() < 55) {
          tooClose = true;
          break;
        }
      }
      if (tooClose) continue;

      final treeHeight = 12.0 + rng.nextDouble() * 18;
      final treeColor = world.treeColors[rng.nextInt(world.treeColors.length)];
      final alpha = 0.25 + rng.nextDouble() * 0.35;

      // Shadow
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(tx + 2, ty + treeHeight * 0.5 + 3),
          width: treeHeight * 0.8,
          height: treeHeight * 0.2,
        ),
        Paint()..color = Colors.black.withValues(alpha: 0.15),
      );

      // Trunk
      final trunkPaint = Paint()
        ..color = const Color(0xFF4E342E).withValues(alpha: alpha + 0.1);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(tx, ty + treeHeight * 0.3),
            width: treeHeight * 0.12,
            height: treeHeight * 0.5,
          ),
          const Radius.circular(2),
        ),
        trunkPaint,
      );

      // Three layered triangles (Mario style)
      for (int layer = 0; layer < 3; layer++) {
        final layerOffset = layer * treeHeight * 0.22;
        final layerWidth = treeHeight * (0.7 - layer * 0.08);
        final treePaint = Paint()
          ..color = treeColor.withValues(alpha: alpha - layer * 0.05);

        final path = Path()
          ..moveTo(tx, ty - treeHeight * 0.6 + layerOffset)
          ..lineTo(tx - layerWidth * 0.5, ty - treeHeight * 0.1 + layerOffset)
          ..lineTo(tx + layerWidth * 0.5, ty - treeHeight * 0.1 + layerOffset)
          ..close();
        canvas.drawPath(path, treePaint);
      }
    }

    // Small bushes
    for (int i = 0; i < 10; i++) {
      final bx = rng.nextDouble() * size.width;
      final by = rng.nextDouble() * size.height;

      bool tooClose = false;
      for (final n in nodes) {
        final nx = n.position.dx * size.width;
        final ny = n.position.dy * size.height;
        if ((bx - nx).abs() < 45 && (by - ny).abs() < 45) {
          tooClose = true;
          break;
        }
      }
      if (tooClose) continue;

      final bushSize = 6.0 + rng.nextDouble() * 10;
      final bushColor = world.treeColors[rng.nextInt(world.treeColors.length)];
      final paint = Paint()..color = bushColor.withValues(alpha: 0.2 + rng.nextDouble() * 0.2);

      canvas.drawCircle(Offset(bx - bushSize * 0.3, by), bushSize * 0.5, paint);
      canvas.drawCircle(Offset(bx + bushSize * 0.3, by), bushSize * 0.5, paint);
      canvas.drawCircle(Offset(bx, by - bushSize * 0.3), bushSize * 0.55, paint);
    }

    // Rocks
    for (int i = 0; i < 6; i++) {
      final rx = rng.nextDouble() * size.width;
      final ry = rng.nextDouble() * size.height;

      bool tooClose = false;
      for (final n in nodes) {
        final nx = n.position.dx * size.width;
        final ny = n.position.dy * size.height;
        if ((rx - nx).abs() < 45 && (ry - ny).abs() < 45) {
          tooClose = true;
          break;
        }
      }
      if (tooClose) continue;

      final rockSize = 4.0 + rng.nextDouble() * 8;

      canvas.drawOval(
        Rect.fromCenter(center: Offset(rx + 1, ry + 2), width: rockSize * 1.6, height: rockSize * 0.7),
        Paint()..color = Colors.black.withValues(alpha: 0.1),
      );

      canvas.drawOval(
        Rect.fromCenter(center: Offset(rx, ry), width: rockSize * 1.4, height: rockSize * 0.9),
        Paint()..color = Colors.grey.shade800.withValues(alpha: 0.25),
      );

      canvas.drawOval(
        Rect.fromCenter(center: Offset(rx - 1, ry - 1), width: rockSize * 0.8, height: rockSize * 0.5),
        Paint()..color = Colors.grey.shade600.withValues(alpha: 0.12),
      );
    }
  }

  void _drawPath(Canvas canvas, Size size) {
    final path = Path();
    path.moveTo(
      nodes.first.position.dx * size.width,
      nodes.first.position.dy * size.height,
    );

    for (int i = 1; i < nodes.length; i++) {
      final prev = nodes[i - 1].position;
      final curr = nodes[i].position;

      final px = prev.dx * size.width;
      final py = prev.dy * size.height;
      final cx = curr.dx * size.width;
      final cy = curr.dy * size.height;

      final midX = (px + cx) / 2;
      final midY = (py + cy) / 2;
      final dx = cx - px;
      final dy = cy - py;
      final curveOffset = (i.isEven ? 1 : -1) * 20.0;

      path.quadraticBezierTo(
        midX + (dy.abs() > 10 ? curveOffset : 0),
        midY + (dx.abs() > 10 ? curveOffset : 0),
        cx,
        cy,
      );
    }

    // Shadow
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 22
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );

    // Outer border
    canvas.drawPath(
      path,
      Paint()
        ..color = world.pathBorder
        ..style = PaintingStyle.stroke
        ..strokeWidth = 20
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // Inner path
    canvas.drawPath(
      path,
      Paint()
        ..color = world.pathColor.withValues(alpha: 0.85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 14
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // Centre highlight
    canvas.drawPath(
      path,
      Paint()
        ..color = world.pathColor.withValues(alpha: 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // Dotted centre line
    final dotPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.12)
      ..style = PaintingStyle.fill;

    final pathMetrics = path.computeMetrics();
    for (final metric in pathMetrics) {
      double distance = 0;
      while (distance < metric.length) {
        final tangent = metric.getTangentForOffset(distance);
        if (tangent != null) {
          canvas.drawCircle(tangent.position, 1.5, dotPaint);
        }
        distance += 12;
      }
    }

    // Mastered path segments (green overlay)
    for (int i = 1; i < nodes.length; i++) {
      if (nodes[i - 1].state == NodeState.mastered &&
          nodes[i].state == NodeState.mastered) {
        final segPath = Path();
        final prev = nodes[i - 1].position;
        final curr = nodes[i].position;
        final px = prev.dx * size.width;
        final py = prev.dy * size.height;
        final cx = curr.dx * size.width;
        final cy = curr.dy * size.height;
        final midX = (px + cx) / 2;
        final midY = (py + cy) / 2;
        final dx = cx - px;
        final dy = cy - py;
        final curveOffset = (i.isEven ? 1 : -1) * 20.0;

        segPath.moveTo(px, py);
        segPath.quadraticBezierTo(
          midX + (dy.abs() > 10 ? curveOffset : 0),
          midY + (dx.abs() > 10 ? curveOffset : 0),
          cx,
          cy,
        );

        canvas.drawPath(
          segPath,
          Paint()
            ..color = const Color(0xFF4CAF50).withValues(alpha: 0.3)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 14
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round,
        );
      }
    }
  }

  void _drawParticles(Canvas canvas, Size size) {
    final rng = Random(world.name.hashCode + 777);
    final paint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < 15; i++) {
      final baseX = rng.nextDouble() * size.width;
      final baseY = rng.nextDouble() * size.height;
      final speed = 0.3 + rng.nextDouble() * 0.7;
      final phase = rng.nextDouble();

      final t = (particleValue * speed + phase) % 1.0;
      final driftX = sin(t * 2 * pi) * 8;
      final driftY = cos(t * 3 * pi) * 5 - t * 20;

      final alpha = sin(t * pi) * 0.4;
      if (alpha <= 0) continue;

      paint.color = world.accentColor.withValues(alpha: alpha.clamp(0.0, 0.35));
      canvas.drawCircle(
        Offset(baseX + driftX, (baseY + driftY) % size.height),
        1 + sin(t * pi) * 1.5,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant WorldMapPainter oldDelegate) => true;
}
