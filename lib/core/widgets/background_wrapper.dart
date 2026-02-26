import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:outcall/core/widgets/connectivity_banner.dart';

/// A wrapper widget that provides a tiled, blurred background pattern.
/// This ensures a consistent "textured" look throughout the application.
class BackgroundWrapper extends StatelessWidget {
  final Widget child;
  final double tilingOpacity;
  final double blurSigma;
  final double overlayOpacity;

  const BackgroundWrapper({
    super.key,
    required this.child,
    this.tilingOpacity = 0.15, // Subtle texture on charcoal
    this.blurSigma = 8.0,      // More blur for smoother dark background
    this.overlayOpacity = 0.7, // Darker overlay for deep charcoal feel
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // The background color from the theme
        Positioned.fill(
          child: Container(
            color: Theme.of(context).scaffoldBackgroundColor,
          ),
        ),
        
        // Tiled blurred background
        Positioned.fill(
          child: Opacity(
            opacity: tilingOpacity,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
              child: Container(
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/images/forest_pattern.png'),
                    repeat: ImageRepeat.repeat,
                    alignment: Alignment.topLeft,
                    scale: 2.0, // Increased scale for a larger, more subtle pattern
                  ),
                ),
              ),
            ),
          ),
        ),
        
        // Overlay for readability
        Positioned.fill(
          child: Container(
            color: Colors.black.withValues(alpha: overlayOpacity),
          ),
        ),
        
        // The actual content with connectivity banner
        ConnectivityBanner(child: child),
      ],
    );
  }
}
