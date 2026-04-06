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
        // Background matching the trees background from rating screen
        Positioned.fill(
          child: Image.asset(
            'assets/images/forest_background.webp',
            fit: BoxFit.cover,
            alignment: Alignment.center,
          ),
        ),
        
        // Theme-aware overlay mask that restores the App Theme picker functionality
        Positioned.fill(
          child: Container(
            color: Theme.of(context).scaffoldBackgroundColor.withValues(
              alpha: Theme.of(context).brightness == Brightness.dark ? 0.65 : 0.88,
            ),
          ),
        ),
        
        // The actual content with connectivity banner
        ConnectivityBanner(child: child),
      ],
    );
  }
}
