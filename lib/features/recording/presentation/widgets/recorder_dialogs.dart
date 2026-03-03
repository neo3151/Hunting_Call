import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:outcall/core/theme/app_colors.dart';

/// Shows a dialog explaining why microphone access is needed.
///
/// [onGranted] is called if the user grants permission after tapping "Allow".
void showMicPermissionDeniedDialog(BuildContext context, {VoidCallback? onGranted}) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.of(ctx).surface,
      title: Row(
        children: [
          const Icon(Icons.mic_off, color: Colors.orangeAccent),
          const SizedBox(width: 12),
          Text('Microphone Access', style: GoogleFonts.oswald(color: AppColors.of(ctx).textPrimary)),
        ],
      ),
      content: Text(
        'We need microphone access to record your hunting calls. This helps us analyze your technique and provide scoring.',
        style: TextStyle(color: AppColors.of(ctx).textSecondary),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text('Not Now', style: TextStyle(color: AppColors.of(ctx).textTertiary)),
        ),
        ElevatedButton(
          onPressed: () async {
            Navigator.pop(ctx);
            final status = await Permission.microphone.request();
            if (status.isGranted) {
              onGranted?.call();
            } else if (status.isPermanentlyDenied) {
              await openAppSettings();
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(ctx).primaryColor,
            foregroundColor: AppColors.of(ctx).background,
          ),
          child: const Text('Allow'),
        ),
      ],
    ),
  );
}

/// Shows a dialog directing the user to app settings when mic permission
/// is permanently denied.
void showMicPermissionSettingsDialog(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.of(ctx).surface,
      title: Row(
        children: [
          const Icon(Icons.settings, color: Colors.orangeAccent),
          const SizedBox(width: 12),
          Text('Permission Required', style: GoogleFonts.oswald(color: AppColors.of(ctx).textPrimary)),
        ],
      ),
      content: Text(
        'Microphone access is disabled in system settings. Please enable it to record hunting calls.',
        style: TextStyle(color: AppColors.of(ctx).textSecondary),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text('Cancel', style: TextStyle(color: AppColors.of(ctx).textTertiary)),
        ),
        ElevatedButton(
          onPressed: () async {
            final navigator = Navigator.of(ctx);
            await openAppSettings();
            navigator.pop();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(ctx).primaryColor,
            foregroundColor: AppColors.of(ctx).background,
          ),
          child: const Text('Open Settings'),
        ),
      ],
    ),
  );
}
