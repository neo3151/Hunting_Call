import 'package:flutter/material.dart';

/// Staggered entrance animation — fade + slide up with configurable delay.
///
/// Usage:
/// ```dart
/// StaggeredFadeSlide(
///   index: 0,      // Item position (0, 1, 2, ...)
///   child: MyCard(),
/// )
/// ```
class StaggeredFadeSlide extends StatelessWidget {
  final int index;
  final Widget child;
  final Duration baseDelay;
  final Duration staggerDelay;
  final Duration duration;
  final double slideOffset;

  const StaggeredFadeSlide({
    super.key,
    required this.index,
    required this.child,
    this.baseDelay = const Duration(milliseconds: 100),
    this.staggerDelay = const Duration(milliseconds: 80),
    this.duration = const Duration(milliseconds: 500),
    this.slideOffset = 20.0,
  });

  @override
  Widget build(BuildContext context) {
    final totalDelay = baseDelay + staggerDelay * index;

    return TweenAnimationBuilder<double>(
      duration: duration + totalDelay,
      curve: Curves.easeOutCubic,
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, _) {
        // Account for the stagger delay by mapping the animation progress
        final delayFraction = totalDelay.inMilliseconds /
            (duration.inMilliseconds + totalDelay.inMilliseconds);
        final adjustedValue =
            ((value - delayFraction) / (1.0 - delayFraction)).clamp(0.0, 1.0);

        return Opacity(
          opacity: adjustedValue,
          child: Transform.translate(
            offset: Offset(0, slideOffset * (1.0 - adjustedValue)),
            child: child,
          ),
        );
      },
    );
  }
}
