import 'dart:ui';
import 'package:flutter/material.dart';

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
    this.tilingOpacity = 0.35, // Increased from 0.15
    this.blurSigma = 6.0,      // Decreased from 10.0 (less blurry = more viewable)
    this.overlayOpacity = 0.5, // Decreased from 0.7 (lighter overlay)
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
                    image: AssetImage('assets/images/logo.png'),
                    repeat: ImageRepeat.repeat,
                    alignment: Alignment.topLeft,
                    scale: 0.5,
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
        
        // The actual content
        child,
      ],
    );
  }
}
