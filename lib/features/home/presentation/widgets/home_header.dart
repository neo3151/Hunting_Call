import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:outcall/l10n/app_localizations.dart';
import 'package:outcall/core/theme/app_colors.dart';

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
    final palette = AppColors.of(context);
    final isDark = AppColors.isDark(context);
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 60, 24, 40),
          decoration: BoxDecoration(
            color: isDark ? palette.surface.withValues(alpha: 0.4) : palette.surface.withValues(alpha: 0.6),
            borderRadius:
                const BorderRadius.vertical(bottom: Radius.circular(32)),
            border: Border.all(color: palette.border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: MergeSemantics(
                  child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(S.of(context).welcomeBack,
                        style: GoogleFonts.oswald(
                            color: palette.textSecondary,
                            fontSize: 28,
                            fontWeight: FontWeight.w300,
                            letterSpacing: 1.0)),
                    Text(userName.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.oswald(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: palette.textPrimary,
                            height: 1.1)),
                  ],
                ),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildCloudBadge(),
                  const SizedBox(width: 8),
                  _buildSettingsButton(palette),
                  const SizedBox(width: 8),
                  _buildSignOutButton(context, palette),
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

    return Semantics(
      label: isCloudMode ? 'Cloud sync enabled' : 'Offline mode',
      child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ExcludeSemantics(
            child: Icon(icon, size: 12, color: badgeColor),
          ),
          const SizedBox(width: 6),
          ExcludeSemantics(
            child: Text(
            label,
            style: GoogleFonts.lato(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: badgeColor,
              letterSpacing: 1.0,
            ),
          ),
          ),
        ],
      ),
    ),
    );
  }

  Widget _buildSettingsButton(AppColorPalette palette) {
    return Container(
      decoration: BoxDecoration(
        color: palette.cardOverlay,
        shape: BoxShape.circle,
      ),
      child: IconButton(
        onPressed: onSettings,
        icon: Icon(Icons.settings_outlined, color: palette.icon, size: 22),
        tooltip: 'Settings',
      ),
    );
  }

  Widget _buildSignOutButton(BuildContext context, AppColorPalette palette) {
    return Container(
      decoration: BoxDecoration(
        color: palette.cardOverlay,
        shape: BoxShape.circle,
      ),
      child: IconButton(
        onPressed: () async {
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: palette.surface,
              title: Text('Sign Out?',
                  style: GoogleFonts.oswald(color: palette.textPrimary)),
              content: Text(
                'Are you sure you want to sign out?',
                style: TextStyle(color: palette.textSecondary),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(S.of(context).cancel,
                      style: TextStyle(color: palette.textTertiary)),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text(S.of(context).signOutAction,
                      style: const TextStyle(
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
        icon: Icon(Icons.logout, color: palette.icon),
        tooltip: 'Sign Out',
      ),
    );
  }
}
