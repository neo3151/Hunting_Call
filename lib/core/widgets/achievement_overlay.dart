import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Full-screen achievement celebration overlay with confetti and animations.
///
/// Usage:
/// ```dart
/// AchievementOverlay.show(context, name: 'First Blood', icon: '🎯',
///     description: 'Record your very first animal call.');
/// ```
class AchievementOverlay {
  static Future<void> show(
    BuildContext context, {
    required String name,
    required String icon,
    required String description,
  }) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Achievement',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (_, anim, __) {
        return _AchievementDialog(
          name: name,
          icon: icon,
          description: description,
          animation: anim,
        );
      },
      transitionBuilder: (_, anim, __, child) {
        return FadeTransition(
          opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
          child: child,
        );
      },
    );
  }
}

class _AchievementDialog extends StatefulWidget {
  final String name;
  final String icon;
  final String description;
  final Animation<double> animation;

  const _AchievementDialog({
    required this.name,
    required this.icon,
    required this.description,
    required this.animation,
  });

  @override
  State<_AchievementDialog> createState() => _AchievementDialogState();
}

class _AchievementDialogState extends State<_AchievementDialog>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _confettiController;
  late Animation<double> _bounceAnim;
  final List<_ConfettiParticle> _particles = [];

  @override
  void initState() {
    super.initState();

    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _bounceAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.15), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.15, end: 0.95), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 0.95, end: 1.0), weight: 40),
    ]).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeInOut,
    ));

    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    // Generate confetti particles
    final rng = Random();
    for (int i = 0; i < 40; i++) {
      _particles.add(_ConfettiParticle(
        color: [
          const Color(0xFF5FF7B6),
          Colors.orangeAccent,
          Colors.amber,
          const Color(0xFF64B5F6),
          Colors.pinkAccent,
        ][rng.nextInt(5)],
        startX: rng.nextDouble(),
        startY: rng.nextDouble() * 0.3,
        velocityX: (rng.nextDouble() - 0.5) * 2,
        velocityY: rng.nextDouble() * 3 + 1,
        rotation: rng.nextDouble() * pi * 2,
        size: rng.nextDouble() * 6 + 4,
      ));
    }

    _scaleController.forward();
    _confettiController.forward();

    // Auto-dismiss after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    });
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Material(
        color: Colors.transparent,
        child: Stack(
          children: [
            // Confetti layer
            AnimatedBuilder(
              animation: _confettiController,
              builder: (context, _) {
                return CustomPaint(
                  size: MediaQuery.of(context).size,
                  painter: _ConfettiPainter(
                    particles: _particles,
                    progress: _confettiController.value,
                  ),
                );
              },
            ),
            // Achievement card
            Center(
              child: AnimatedBuilder(
                animation: _bounceAnim,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _bounceAnim.value,
                    child: child,
                  );
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 40),
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A2E),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: const Color(0xFF5FF7B6).withValues(alpha: 0.4),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF5FF7B6).withValues(alpha: 0.2),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '🏆 ACHIEVEMENT UNLOCKED',
                        style: GoogleFonts.oswald(
                          color: const Color(0xFF5FF7B6),
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        widget.icon,
                        style: const TextStyle(fontSize: 56),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        widget.name,
                        style: GoogleFonts.oswald(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.description,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.lato(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'TAP TO CONTINUE',
                        style: GoogleFonts.lato(
                          color: Colors.white38,
                          fontSize: 11,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConfettiParticle {
  final Color color;
  final double startX;
  final double startY;
  final double velocityX;
  final double velocityY;
  final double rotation;
  final double size;

  _ConfettiParticle({
    required this.color,
    required this.startX,
    required this.startY,
    required this.velocityX,
    required this.velocityY,
    required this.rotation,
    required this.size,
  });
}

class _ConfettiPainter extends CustomPainter {
  final List<_ConfettiParticle> particles;
  final double progress;

  _ConfettiPainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final x = (p.startX + p.velocityX * progress) * size.width;
      final y = (p.startY + p.velocityY * progress) * size.height;
      final opacity = (1.0 - progress).clamp(0.0, 1.0);

      final paint = Paint()
        ..color = p.color.withValues(alpha: opacity)
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(p.rotation + progress * pi * 4);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 0.6),
          const Radius.circular(1),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter old) => old.progress != progress;
}
