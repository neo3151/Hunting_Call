import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:outcall/core/widgets/background_wrapper.dart';
import 'package:outcall/features/settings/presentation/controllers/settings_controller.dart';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:outcall/features/profile/presentation/controllers/profile_controller.dart';
import 'package:outcall/features/settings/presentation/privacy_policy_screen.dart';
import 'package:outcall/features/settings/presentation/calibration_screen.dart';
import 'package:outcall/l10n/app_localizations.dart';
import 'package:outcall/core/theme/app_theme.dart';
import 'package:outcall/core/theme/app_colors.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsNotifierProvider);
    final colors = AppColors.of(context);


    return Scaffold(
      body: BackgroundWrapper(
        child: SafeArea(
          child: Column(
            children: [
              // App bar
              Container(
                padding: const EdgeInsets.fromLTRB(8, 8, 16, 16),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back, color: colors.textPrimary),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'SETTINGS',
                      style: GoogleFonts.oswald(
                        color: colors.textPrimary,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              // Content
              Expanded(
                child: settingsAsync.when(
                  loading: () => Center(
                    child: CircularProgressIndicator(color: Theme.of(context).primaryColor),
                  ),
                  error: (e, _) => Center(
                    child: Text('Error: $e',
                        style: TextStyle(color: colors.textSecondary)),
                  ),
                  data: (settings) {
                    final notifier =
                        ref.read(settingsNotifierProvider.notifier);
                    return SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _sectionTitle(context, S.of(context).appearance),
                          _settingsTile(
                            context: context,
                            icon: Icons.brightness_6_outlined,
                            title: S.of(context).darkMode,
                            subtitle: S.of(context).darkModeSubtitle,
                            trailing: SegmentedButton<ThemeMode>(
                              segments: [
                                ButtonSegment(value: ThemeMode.system, label: Text(S.of(context).themeSys, style: const TextStyle(fontSize: 10))),
                                ButtonSegment(value: ThemeMode.light, label: Text(S.of(context).themeLight, style: const TextStyle(fontSize: 10))),
                                ButtonSegment(value: ThemeMode.dark, label: Text(S.of(context).themeDark, style: const TextStyle(fontSize: 10))),
                              ],
                              selected: {settings.themeMode},
                              onSelectionChanged: (v) => notifier.setThemeMode(v.first),
                              style: ButtonStyle(
                                backgroundColor: WidgetStateProperty.resolveWith((states) {
                                  if (states.contains(WidgetState.selected)) {
                                    return Theme.of(context).primaryColor.withValues(alpha: 0.3);
                                  }
                                  return colors.cardOverlay;
                                }),
                                foregroundColor: WidgetStateProperty.all(colors.textPrimary),
                                side: WidgetStateProperty.all(BorderSide(color: colors.border)),
                              ),
                            ),
                          ),
                          Divider(color: colors.divider),
                          _settingsTile(
                            context: context,
                            icon: Icons.palette_outlined,
                            title: S.of(context).appTheme,
                            subtitle: S.of(context).appThemeSubtitle,
                            trailing: SegmentedButton<AppTheme>(
                              segments: [
                                ButtonSegment(
                                  value: AppTheme.classic,
                                  label: Container(width: 16, height: 16, decoration: const BoxDecoration(color: Color(0xFFFF8C00), shape: BoxShape.circle)),
                                ),
                                ButtonSegment(
                                  value: AppTheme.midnight,
                                  label: Container(width: 16, height: 16, decoration: const BoxDecoration(color: Color(0xFF3A86FF), shape: BoxShape.circle)),
                                ),
                                ButtonSegment(
                                  value: AppTheme.forest,
                                  label: Container(width: 16, height: 16, decoration: const BoxDecoration(color: Color(0xFF2ECC71), shape: BoxShape.circle)),
                                ),
                                ButtonSegment(
                                  value: AppTheme.hunter,
                                  label: Container(width: 16, height: 16, decoration: const BoxDecoration(color: Color(0xFFE74C3C), shape: BoxShape.circle)),
                                ),
                              ],
                              selected: {settings.theme},
                              showSelectedIcon: false,
                              onSelectionChanged: (v) =>
                                  notifier.setTheme(v.first),
                              style: ButtonStyle(
                                backgroundColor:
                                    WidgetStateProperty.resolveWith((states) {
                                  if (states
                                      .contains(WidgetState.selected)) {
                                    return Theme.of(context).primaryColor
                                        .withValues(alpha: 0.3);
                                  }
                                  return colors.cardOverlay;
                                }),
                                foregroundColor:
                                    WidgetStateProperty.all(colors.textPrimary),
                                side: WidgetStateProperty.all(
                                    BorderSide(color: colors.border)),
                              ),
                            ),
                          ),
                          Divider(color: colors.divider),

                          _sectionTitle(context, S.of(context).preferences),
                          _settingsTile(
                            context: context,
                            icon: Icons.straighten,
                            title: S.of(context).distanceUnit,
                            subtitle: settings.distanceUnit == 'imperial'
                                ? S.of(context).distanceUnitImperial
                                : S.of(context).distanceUnitMetric,
                            trailing: SegmentedButton<String>(
                              segments: [
                                ButtonSegment(
                                    value: 'imperial',
                                    label: Text(S.of(context).unitImperial,
                                        style: const TextStyle(fontSize: 11))),
                                ButtonSegment(
                                    value: 'metric',
                                    label: Text(S.of(context).unitMetric,
                                        style: const TextStyle(fontSize: 11))),
                              ],
                              selected: {settings.distanceUnit},
                              onSelectionChanged: (v) =>
                                  notifier.setDistanceUnit(v.first),
                              style: ButtonStyle(
                                backgroundColor:
                                    WidgetStateProperty.resolveWith((states) {
                                  if (states
                                      .contains(WidgetState.selected)) {
                                    return Theme.of(context).primaryColor
                                        .withValues(alpha: 0.3);
                                  }
                                  return colors.cardOverlay;
                                }),
                                foregroundColor:
                                    WidgetStateProperty.all(colors.textPrimary),
                                side: WidgetStateProperty.all(
                                    BorderSide(color: colors.border)),
                              ),
                            ),
                          ),
                          Divider(color: colors.divider),
                          _settingsTile(
                            context: context,
                            icon: Icons.notifications_outlined,
                            title: S.of(context).notifications,
                            subtitle: S.of(context).notificationsSubtitle,
                            trailing: Switch(
                              value: settings.notificationsEnabled,
                              onChanged: notifier.setNotificationsEnabled,
                              activeThumbColor: Theme.of(context).primaryColor,
                            ),
                          ),
                          Divider(color: colors.divider),

                          _sectionTitle(context, S.of(context).audioAndHaptics),
                          _settingsTile(
                            context: context,
                            icon: Icons.volume_up_outlined,
                            title: S.of(context).soundEffects,
                            subtitle: S.of(context).soundEffectsSubtitle,
                            trailing: Switch(
                              value: settings.soundEffects,
                              onChanged: notifier.setSoundEffects,
                              activeThumbColor: Theme.of(context).primaryColor,
                            ),
                          ),
                          Divider(color: colors.divider),
                          _settingsTile(
                            context: context,
                            icon: Icons.vibration,
                            title: S.of(context).hapticFeedback,
                            subtitle: S.of(context).hapticFeedbackSubtitle,
                            trailing: Switch(
                              value: settings.hapticFeedback,
                              onChanged: notifier.setHapticFeedback,
                              activeThumbColor: Theme.of(context).primaryColor,
                            ),
                          ),
                          Divider(color: colors.divider),
                          _settingsTile(
                            context: context,
                            icon: Icons.tune,
                            title: 'Calibrate Scoring',
                            subtitle: settings.calibration.isCalibrated
                                ? 'Last: ${_formatDate(settings.calibration.calibratedAt!)}'
                                : 'Adjust scores for your device',
                            trailing: Icon(Icons.chevron_right, color: colors.iconSubtle),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const CalibrationScreen()),
                            ),
                          ),
                          Divider(color: colors.divider),

                          _sectionTitle(context, S.of(context).performanceAndStorage),
                          _settingsTile(
                            context: context,
                            icon: Icons.high_quality,
                            title: S.of(context).imageQuality,
                            subtitle: S.of(context).imageQualitySubtitle,
                            trailing: SegmentedButton<String>(
                              segments: [
                                ButtonSegment(value: 'low', label: Text(S.of(context).qualityLow, style: const TextStyle(fontSize: 10))),
                                ButtonSegment(value: 'medium', label: Text(S.of(context).qualityMedium, style: const TextStyle(fontSize: 10))),
                                ButtonSegment(value: 'high', label: Text(S.of(context).qualityHigh, style: const TextStyle(fontSize: 10))),
                              ],
                              selected: {settings.imageQuality},
                              onSelectionChanged: (v) => notifier.setImageQuality(v.first),
                              style: ButtonStyle(
                                backgroundColor: WidgetStateProperty.resolveWith((states) {
                                  if (states.contains(WidgetState.selected)) {
                                    return Theme.of(context).primaryColor.withValues(alpha: 0.3);
                                  }
                                  return colors.cardOverlay;
                                }),
                                foregroundColor: WidgetStateProperty.all(colors.textPrimary),
                                side: WidgetStateProperty.all(BorderSide(color: colors.border)),
                              ),
                            ),
                          ),
                          Divider(color: colors.divider),
                          _settingsTile(
                            context: context,
                            icon: Icons.cleaning_services,
                            title: S.of(context).audioCleanup,
                            subtitle: S.of(context).audioCleanupSubtitle,
                            trailing: DropdownButton<int>(
                              value: settings.autoCleanupHours,
                              dropdownColor: colors.surface,
                              underline: const SizedBox.shrink(),
                              items: [
                                DropdownMenuItem(value: 0, child: Text('Never', style: TextStyle(color: colors.textPrimary, fontSize: 13))),
                                DropdownMenuItem(value: 1, child: Text('1h', style: TextStyle(color: colors.textPrimary, fontSize: 13))),
                                DropdownMenuItem(value: 6, child: Text('6h', style: TextStyle(color: colors.textPrimary, fontSize: 13))),
                                DropdownMenuItem(value: 24, child: Text('24h', style: TextStyle(color: colors.textPrimary, fontSize: 13))),
                                DropdownMenuItem(value: 168, child: Text('7d', style: TextStyle(color: colors.textPrimary, fontSize: 13))),
                              ],
                              onChanged: (v) => v != null ? notifier.setAutoCleanupHours(v) : null,
                            ),
                          ),
                          Divider(color: colors.divider),

                          _sectionTitle(context, S.of(context).feedbackAndSupport),
                          _settingsTile(
                            context: context,
                            icon: Icons.bug_report_outlined,
                            title: S.of(context).sendFeedback,
                            subtitle: S.of(context).sendFeedbackSubtitle,
                            trailing: Icon(Icons.chevron_right, color: colors.iconSubtle),
                            onTap: () => _sendFeedbackEmail(context, ref),
                          ),
                          Divider(color: colors.divider),

                          _sectionTitle(context, S.of(context).aboutSection),
                          _settingsTile(
                            context: context,
                            icon: Icons.shield_outlined,
                            title: S.of(context).privacyPolicy,
                            subtitle: S.of(context).privacyPolicySubtitle,
                            trailing: Icon(Icons.chevron_right,
                                color: colors.iconSubtle),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      const PrivacyPolicyScreen()),
                            ),
                          ),
                          Divider(color: colors.divider),
                          FutureBuilder<PackageInfo>(
                            future: PackageInfo.fromPlatform(),
                            builder: (context, snapshot) {
                              final version = snapshot.hasData
                                  ? '${snapshot.data!.version} (Build ${snapshot.data!.buildNumber})'
                                  : 'Loading...';
                              return _settingsTile(
                                context: context,
                                icon: Icons.info_outline,
                                title: 'App Version',
                                subtitle: version,
                                trailing: const SizedBox.shrink(),
                              );
                            },
                          ),
                          const SizedBox(height: 24),

                          // Reset button
                          Center(
                            child: TextButton.icon(
                              onPressed: () async {
                                final confirmed = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    backgroundColor: colors.surface,
                                    title: Text('Reset Settings?',
                                        style: GoogleFonts.oswald(
                                            color: colors.textPrimary)),
                                    content: Text(
                                      'This will restore all settings to their defaults.',
                                      style:
                                          TextStyle(color: colors.textSecondary),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(ctx, false),
                                        child: Text('CANCEL',
                                            style: TextStyle(
                                                color: colors.textTertiary)),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(ctx, true),
                                        child: const Text('RESET',
                                            style: TextStyle(
                                                color: Colors.redAccent,
                                                fontWeight:
                                                    FontWeight.bold)),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirmed == true) {
                                  await notifier.resetToDefaults();
                                }
                              },
                              icon: Icon(Icons.restore,
                                  color: colors.iconSubtle, size: 18),
                              label: Text('Reset to Defaults',
                                  style: GoogleFonts.lato(
                                      color: colors.textSubtle,
                                      fontSize: 13)),
                            ),
                          ),
                          const SizedBox(height: 32),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 12),
      child: Text(
        title,
        style: GoogleFonts.oswald(
          color: Theme.of(context).primaryColor,
          fontSize: 14,
          fontWeight: FontWeight.bold,
          letterSpacing: 2.0,
        ),
      ),
    );
  }

  Widget _settingsTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget trailing,
    VoidCallback? onTap,
  }) {
    final colors = AppColors.of(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxTrailingWidth = (constraints.maxWidth - 56) * 0.55;
            return Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: colors.cardOverlay,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: colors.textTertiary, size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: GoogleFonts.lato(
                              color: colors.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text(subtitle,
                          style: GoogleFonts.lato(
                              color: colors.textSubtle, fontSize: 12)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxTrailingWidth),
                  child: trailing,
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _sendFeedbackEmail(BuildContext context, WidgetRef ref) async {
    final packageInfo = await PackageInfo.fromPlatform();
    final deviceInfo = DeviceInfoPlugin();
    String deviceModel = 'Unknown Device';
    String osVersion = 'Unknown OS';

    if (Platform.isAndroid) {
      final info = await deviceInfo.androidInfo;
      deviceModel = '${info.manufacturer} ${info.model}';
      osVersion = 'Android ${info.version.release} (SDK ${info.version.sdkInt})';
    } else if (Platform.isIOS) {
      final info = await deviceInfo.iosInfo;
      deviceModel = info.utsname.machine;
      osVersion = 'iOS ${info.systemVersion}';
    } else if (Platform.isLinux) {
      final info = await deviceInfo.linuxInfo;
      deviceModel = info.prettyName;
      osVersion = info.versionId ?? 'Unknown';
    }

    final String appVersion = '${packageInfo.version}+${packageInfo.buildNumber}';
    final profileState = ref.read(profileNotifierProvider);
    final String userId = profileState.profile?.id ?? 'Not logged in';

    final String body = '''
Please describe the issue or feedback below:


========================
Diagnostic Info (Please leave this section intact):
App Version: $appVersion
Device: $deviceModel
OS: $osVersion
User ID: $userId
========================
''';

    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'support@huntingcalls.app',
      queryParameters: {
        'subject': 'Outcall Alpha Feedback - $appVersion',
        'body': body,
      },
    );

    try {
      if (!await launchUrl(emailLaunchUri)) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open email app.')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }
}
