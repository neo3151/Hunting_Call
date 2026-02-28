import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Header bar for the home screen showing welcome text and cloud/sign-out controls.
class HomeHeader extends StatelessWidget {
  final String userName;
  final bool isCloudMode;
  final VoidCallback onSignOut;
  final VoidCallback? onSettings;

  const HomeHeader({
    super.key,
    required this.userName,
    required this.isCloudMode,
    required this.onSignOut,
    this.onSettings,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 60, 24, 40),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A1A1A).withValues(alpha: 0.4) : Colors.white.withValues(alpha: 0.6),
            borderRadius:
                const BorderRadius.vertical(bottom: Radius.circular(32)),
            border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.1)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('WELCOME BACK,',
                        style: GoogleFonts.oswald(
                            color: isDark ? Colors.white70 : Colors.black54,
                            fontSize: 28,
                            fontWeight: FontWeight.w300,
                            letterSpacing: 1.0)),
                    Text(userName.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.oswald(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                            height: 1.1)),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildCloudBadge(),
                  const SizedBox(width: 8),
                  _buildSettingsButton(isDark),
                  const SizedBox(width: 8),
                  _buildSignOutButton(context, isDark),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCloudBadge() {
    final badgeColor =
        isCloudMode ? Colors.greenAccent : Colors.amberAccent;
    final bgColor = isCloudMode
        ? Colors.green.withValues(alpha: 0.2)
        : Colors.amber.withValues(alpha: 0.2);
    final borderColor = badgeColor.withValues(alpha: 0.5);
    final label = isCloudMode ? 'CLOUD' : 'OFF-GRID';
    final icon = isCloudMode ? Icons.cloud_done : Icons.wifi_off;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: badgeColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.lato(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: badgeColor,
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsButton(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        onPressed: onSettings,
        icon: Icon(Icons.settings_outlined, color: isDark ? Colors.white70 : Colors.black54, size: 22),
        tooltip: 'Settings',
      ),
    );
  }

  Widget _buildSignOutButton(BuildContext context, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        onPressed: () async {
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
              title: Text('Sign Out?',
                  style: GoogleFonts.oswald(color: isDark ? Colors.white : Colors.black87)),
              content: Text(
                'Are you sure you want to sign out?',
                style: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text('CANCEL',
                      style: TextStyle(color: isDark ? Colors.white54 : Colors.black54)),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('SIGN OUT',
                      style: TextStyle(
                          color: Colors.redAccent,
                          fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          );
          if (confirmed == true) {
            onSignOut();
          }
        },
        icon: Icon(Icons.logout, color: isDark ? Colors.white70 : Colors.black54),
        tooltip: 'Sign Out',
      ),
    );
  }
}
