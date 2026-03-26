import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:outcall/core/theme/app_colors.dart';

/// Animated score reveal widget that counts up from 0 to the final score
/// with a scaling entrance animation.
class AnimatedScoreReveal extends StatefulWidget {
  final double score;
  final Duration duration;
  final TextStyle? style;

  const AnimatedScoreReveal({
    super.key,
    required this.score,
    this.duration = const Duration(milliseconds: 1200),
    this.style,
  });

  @override
  State<AnimatedScoreReveal> createState() => _AnimatedScoreRevealState();
}

class _AnimatedScoreRevealState extends State<AnimatedScoreReveal>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _valueAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);

    _valueAnimation = Tween<double>(begin: 0, end: widget.score).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0, 0.6, curve: Curves.elasticOut),
      ),
    );

    _opacityAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0, 0.3, curve: Curves.easeIn),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _opacityAnimation.value,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: Text(
              '${_valueAnimation.value.toInt()}%',
              style: widget.style ??
                  GoogleFonts.oswald(
                    fontSize: 64,
                    fontWeight: FontWeight.bold,
                    color: _scoreColor(_valueAnimation.value),
                  ),
            ),
          ),
        );
      },
    );
  }

  Color _scoreColor(double score) {
    if (score >= 85) return AppColors.success;
    if (score >= 70) return const Color(0xFF4FC3F7);
    if (score >= 50) return AppColors.warning;
    return AppColors.error;
  }
}

/// Pulsing celebration animation for achievements and high scores.
class CelebrationBurst extends StatefulWidget {
  final Widget child;
  final bool show;

  const CelebrationBurst({
    super.key,
    required this.child,
    this.show = true,
  });

  @override
  State<CelebrationBurst> createState() => _CelebrationBurstState();
}

class _CelebrationBurstState extends State<CelebrationBurst>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    if (widget.show) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(CelebrationBurst oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.show && !oldWidget.show) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Expanding ring
            if (widget.show)
              Transform.scale(
                scale: 1.0 + (_controller.value * 0.5),
                child: Opacity(
                  opacity: 1.0 - _controller.value,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFFFD700),
                        width: 3,
                      ),
                    ),
                  ),
                ),
              ),
            widget.child,
          ],
        );
      },
    );
  }
}
