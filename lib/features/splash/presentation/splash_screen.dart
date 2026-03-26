import 'dart:async';
import 'dart:math' as math;

import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:outcall/core/services/cloud_audio_service.dart';
import 'package:outcall/core/services/remote_config/remote_config_service.dart';
import 'package:outcall/core/utils/app_logger.dart';
import 'package:outcall/features/auth/presentation/auth_wrapper.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:outcall/core/theme/app_colors.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> with TickerProviderStateMixin {
  late final AnimationController _logoController;
  late final AnimationController _shimmerController;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoOpacity;
  String _appVersion = '';

  @override
  void initState() {
    super.initState();

    // Load real version from pubspec.yaml
    PackageInfo.fromPlatform().then((info) {
      if (mounted) setState(() => _appVersion = 'v${info.version}');
    });

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

    // Wait for both the minimum splash duration (for animation) and background services
    Future.wait([
      Future.delayed(const Duration(milliseconds: 2800)),
      _initDeferredServices(),
    ]).then((_) {
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

  Future<void> _initDeferredServices() async {
    // 1. Ensure Flutter has rendered the first frame of this widget
    await Future.delayed(const Duration(milliseconds: 100));

    // 2. Remove the OS native splash screen to reveal our animated splash
    FlutterNativeSplash.remove();

    // 3. Precache heavy images to prevent jumping when navigating
    if (mounted) {
      precacheImage(const AssetImage('assets/images/forest_pattern.png'), context);
      precacheImage(const AssetImage('assets/images/app_icon.webp'), context);
    }

    // 4. Initialize services deferred from main.dart
    try {
      final remoteConfig = RemoteConfigService(FirebaseRemoteConfig.instance);
      await remoteConfig.initialize();
    } catch (e) {
      AppLogger.d('RemoteConfig init skipped: $e');
    }

    try {
      final cloudAudio = ref.read(cloudAudioServiceProvider);
      await cloudAudio.init();
    } catch (e) {
      AppLogger.d('CloudAudioService init skipped: $e');
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // #15: Clamp text scale on splash to prevent accessibility breakage
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: MediaQuery.of(context).textScaler.clamp(
          minScaleFactor: 0.8,
          maxScaleFactor: 1.35,
        ),
      ),
      child: Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.3),
            radius: 1.2,
            colors: [
              AppColors.surfaceLight, // Dark charcoal center
              Color(0xFF1C1E23), // Darker
              AppColors.surfaceDark, // Near-black edges
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
                            color: AppColors.accentGold.withValues(alpha: 0.15),
                            blurRadius: 60,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                      child: Image.asset(
                        'assets/images/splash_logo.png',
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
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
                                AppColors.accentGoldDark,
                                AppColors.accentGold,
                                AppColors.accentGoldLight,
                                AppColors.accentGold,
                                AppColors.accentGoldDark,
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
                      'Master Your Craft',
                      style: TextStyle(
                        color: AppColors.accentGold.withValues(alpha: 0.7),
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
                child: Text(
                  _appVersion.isNotEmpty ? _appVersion : 'v2.1.0',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF3A3D44),
                    fontSize: 12,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ),
          ],
        ),
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

      paint.color = AppColors.accentGold.withValues(alpha: opacity.clamp(0.0, 1.0));
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
