import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math' as math;
import '../../auth/presentation/auth_wrapper.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _logoController;
  late final AnimationController _shimmerController;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoOpacity;

  @override
  void initState() {
    super.initState();

    // Logo entrance animation
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _logoScale = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeIn),
      ),
    );

    // Shimmer effect
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    // Start logo animation
    _logoController.forward();

    // Navigate after delay
    Timer(const Duration(milliseconds: 2800), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const AuthWrapper(),
            transitionsBuilder: (_, animation, __, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 500),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _logoController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.3),
            radius: 1.2,
            colors: [
              Color(0xFF2D4A2E), // Forest green center
              Color(0xFF1B3320), // Darker green
              Color(0xFF0F1E12), // Near-black green edges
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Subtle forest texture overlay
            Positioned.fill(
              child: CustomPaint(
                painter: _ForestParticlePainter(
                  animation: _shimmerController,
                ),
              ),
            ),

            // Main content
            Center(
              child: AnimatedBuilder(
                animation: _logoController,
                builder: (context, child) {
                  return Opacity(
                    opacity: _logoOpacity.value,
                    child: Transform.scale(
                      scale: _logoScale.value,
                      child: child,
                    ),
                  );
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Logo with golden glow
                    Container(
                      width: 300,
                      height: 300,
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFC9A84C).withValues(alpha: 0.15),
                            blurRadius: 60,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                      child: Image.asset(
                        'assets/images/splash_logo.png',
                        fit: BoxFit.contain,
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Decorative gold divider
                    AnimatedBuilder(
                      animation: _shimmerController,
                      builder: (context, _) {
                        return ShaderMask(
                          shaderCallback: (bounds) {
                            return LinearGradient(
                              colors: const [
                                Color(0xFF8B7333),
                                Color(0xFFC9A84C),
                                Color(0xFFE8D48B),
                                Color(0xFFC9A84C),
                                Color(0xFF8B7333),
                              ],
                              stops: const [0.0, 0.3, 0.5, 0.7, 1.0],
                              transform: _SlidingGradientTransform(
                                _shimmerController.value,
                              ),
                            ).createShader(bounds);
                          },
                          child: SizedBox(
                            width: 200,
                            height: 2,
                            child: Container(color: Colors.white),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 16),

                    // Tagline
                    Text(
                      'Master Your Hunting Calls',
                      style: TextStyle(
                        color: const Color(0xFFC9A84C).withValues(alpha: 0.7),
                        fontSize: 14,
                        fontWeight: FontWeight.w300,
                        letterSpacing: 3.0,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom version text
            Positioned(
              bottom: 32,
              left: 0,
              right: 0,
              child: AnimatedBuilder(
                animation: _logoController,
                builder: (context, child) {
                  return Opacity(
                    opacity: _logoOpacity.value * 0.5,
                    child: child,
                  );
                },
                child: const Text(
                  'v1.3.0',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF4A6B4D),
                    fontSize: 12,
                    letterSpacing: 1.5,
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

/// Floating golden particle painter for ambient forest atmosphere
class _ForestParticlePainter extends CustomPainter {
  final Animation<double> animation;
  final List<_Particle> _particles;

  _ForestParticlePainter({required this.animation})
      : _particles = List.generate(20, (i) => _Particle(i)),
        super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (final particle in _particles) {
      final progress = (animation.value + particle.offset) % 1.0;
      final x = particle.x * size.width;
      final y = size.height * (1.0 - progress);
      final opacity = math.sin(progress * math.pi) * particle.maxOpacity;

      paint.color = const Color(0xFFC9A84C).withValues(alpha: opacity.clamp(0.0, 1.0));
      canvas.drawCircle(Offset(x, y), particle.radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ForestParticlePainter oldDelegate) => true;
}

class _Particle {
  final double x;
  final double offset;
  final double radius;
  final double maxOpacity;

  _Particle(int index)
      : x = (index * 0.0618 + 0.1) % 1.0,
        offset = (index * 0.137) % 1.0,
        radius = 1.0 + (index % 3) * 0.5,
        maxOpacity = 0.1 + (index % 5) * 0.04;
}

/// Slides a gradient across the widget for shimmer effect
class _SlidingGradientTransform extends GradientTransform {
  final double percent;
  const _SlidingGradientTransform(this.percent);

  @override
  Matrix4 transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * (percent * 2 - 1), 0, 0);
  }
}
