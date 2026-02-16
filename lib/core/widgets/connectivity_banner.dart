import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';

/// Lightweight connectivity banner that shows when the device is offline.
///
/// Uses `dart:io` DNS lookup (no extra packages needed).
/// Auto-hides when connectivity returns.
class ConnectivityBanner extends StatefulWidget {
  final Widget child;

  const ConnectivityBanner({super.key, required this.child});

  @override
  State<ConnectivityBanner> createState() => _ConnectivityBannerState();
}

class _ConnectivityBannerState extends State<ConnectivityBanner>
    with SingleTickerProviderStateMixin {
  bool _isOffline = false;
  Timer? _checkTimer;
  late final AnimationController _slideController;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOut,
    ));

    // Check immediately, then every 5 seconds
    _checkConnectivity();
    _checkTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _checkConnectivity();
    });
  }

  Future<void> _checkConnectivity() async {
    if (!mounted) return;
    try {
      // In tests, InternetAddress.lookup might hang or cause issues with pending timers
      if (Platform.environment.containsKey('FLUTTER_TEST')) {
        return;
      }

      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 3));
      final hasConnection = result.isNotEmpty && result[0].rawAddress.isNotEmpty;
      _setOffline(!hasConnection);
    } catch (_) {
      _setOffline(true);
    }
  }

  void _setOffline(bool offline) {
    if (!mounted) return;
    if (offline != _isOffline) {
      setState(() => _isOffline = offline);
      if (offline) {
        _slideController.forward();
      } else {
        _slideController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _checkTimer?.cancel();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Pad the child down when offline to avoid overlap
        AnimatedPadding(
          duration: const Duration(milliseconds: 300),
          padding: EdgeInsets.only(top: _isOffline ? 32 : 0),
          child: widget.child,
        ),

        // The banner
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SlideTransition(
            position: _slideAnimation,
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.orange.shade800,
                      Colors.orange.shade700,
                    ],
                  ),
                ),
                child: const SafeArea(
                  bottom: false,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.wifi_off_rounded, color: Colors.white, size: 16),
                      SizedBox(width: 8),
                      Text(
                        'No Internet Connection',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
