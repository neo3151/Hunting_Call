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
import 'package:outcall/core/theme/app_theme.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsNotifierProvider);

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
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'SETTINGS',
                      style: GoogleFonts.oswald(
                        color: Colors.white,
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
                        style: const TextStyle(color: Colors.white70)),
                  ),
                  data: (settings) {
                    final notifier =
                        ref.read(settingsNotifierProvider.notifier);
                    return SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _sectionTitle(context, 'APPEARANCE'),
                          _settingsTile(
                            icon: Icons.brightness_6_outlined,
                            title: 'Dark Mode',
                            subtitle: 'Light, Dark, or System',
                            trailing: SegmentedButton<ThemeMode>(
                              segments: const [
                                ButtonSegment(value: ThemeMode.system, label: Text('SYS', style: TextStyle(fontSize: 10))),
                                ButtonSegment(value: ThemeMode.light, label: Text('LGT', style: TextStyle(fontSize: 10))),
                                ButtonSegment(value: ThemeMode.dark, label: Text('DRK', style: TextStyle(fontSize: 10))),
                              ],
                              selected: {settings.themeMode},
                              onSelectionChanged: (v) => notifier.setThemeMode(v.first),
                              style: ButtonStyle(
                                backgroundColor: WidgetStateProperty.resolveWith((states) {
                                  if (states.contains(WidgetState.selected)) {
                                    return Theme.of(context).primaryColor.withValues(alpha: 0.3);
                                  }
                                  return Colors.white.withValues(alpha: 0.05);
                                }),
                                foregroundColor: WidgetStateProperty.all(Colors.white),
                                side: WidgetStateProperty.all(const BorderSide(color: Colors.white24)),
                              ),
                            ),
                          ),
                          const Divider(color: Colors.white12),
                          _settingsTile(
                            icon: Icons.palette_outlined,
                            title: 'App Theme',
                            subtitle: 'Choose your color palette',
                            trailing: SegmentedButton<AppTheme>(
                              segments: [
                                const ButtonSegment(
                                  value: AppTheme.classic,
                                  icon: Icon(Icons.circle, color: Color(0xFFFF8C00), size: 14),
                                  label: Text('ORA', style: TextStyle(fontSize: 10)),
                                ),
                                const ButtonSegment(
                                  value: AppTheme.midnight,
                                  icon: Icon(Icons.circle, color: Color(0xFF3A86FF), size: 14),
                                  label: Text('BLU', style: TextStyle(fontSize: 10)),
                                ),
                                const ButtonSegment(
                                  value: AppTheme.forest,
                                  icon: Icon(Icons.circle, color: Color(0xFF2ECC71), size: 14),
                                  label: Text('GRN', style: TextStyle(fontSize: 10)),
                                ),
                                const ButtonSegment(
                                  value: AppTheme.hunter,
                                  icon: Icon(Icons.circle, color: Color(0xFFE74C3C), size: 14),
                                  label: Text('RED', style: TextStyle(fontSize: 10)),
                                ),
                              ],
                              selected: {settings.theme},
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
                                  return Colors.white.withValues(alpha: 0.05);
                                }),
                                foregroundColor:
                                    WidgetStateProperty.all(Colors.white),
                                side: WidgetStateProperty.all(
                                    const BorderSide(color: Colors.white24)),
                              ),
                            ),
                          ),
                          const Divider(color: Colors.white12),

                          _sectionTitle(context, 'PREFERENCES'),
                          _settingsTile(
                            icon: Icons.straighten,
                            title: 'Distance Unit',
                            subtitle: settings.distanceUnit == 'imperial'
                                ? 'Imperial (yards, °F)'
                                : 'Metric (meters, °C)',
                            trailing: SegmentedButton<String>(
                              segments: const [
                                ButtonSegment(
                                    value: 'imperial',
                                    label: Text('IMP',
                                        style: TextStyle(fontSize: 11))),
                                ButtonSegment(
                                    value: 'metric',
                                    label: Text('MET',
                                        style: TextStyle(fontSize: 11))),
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
                                  return Colors.white.withValues(alpha: 0.05);
                                }),
                                foregroundColor:
                                    WidgetStateProperty.all(Colors.white),
                                side: WidgetStateProperty.all(
                                    const BorderSide(color: Colors.white24)),
                              ),
                            ),
                          ),
                          const Divider(color: Colors.white12),
                          _settingsTile(
                            icon: Icons.notifications_outlined,
                            title: 'Notifications',
                            subtitle: 'Daily challenge reminders',
                            trailing: Switch(
                              value: settings.notificationsEnabled,
                              onChanged: notifier.setNotificationsEnabled,
                              activeThumbColor: Theme.of(context).primaryColor,
                            ),
                          ),
                          const Divider(color: Colors.white12),

                          _sectionTitle(context, 'AUDIO & HAPTICS'),
                          _settingsTile(
                            icon: Icons.volume_up_outlined,
                            title: 'Sound Effects',
                            subtitle: 'UI interaction sounds',
                            trailing: Switch(
                              value: settings.soundEffects,
                              onChanged: notifier.setSoundEffects,
                              activeThumbColor: Theme.of(context).primaryColor,
                            ),
                          ),
                          const Divider(color: Colors.white12),
                          _settingsTile(
                            icon: Icons.vibration,
                            title: 'Haptic Feedback',
                            subtitle: 'Vibration on interactions',
                            trailing: Switch(
                              value: settings.hapticFeedback,
                              onChanged: notifier.setHapticFeedback,
                              activeThumbColor: Theme.of(context).primaryColor,
                            ),
                          ),
                          const Divider(color: Colors.white12),

                          _sectionTitle(context, 'PERFORMANCE & STORAGE'),
                          _settingsTile(
                            icon: Icons.high_quality,
                            title: 'Image Quality',
                            subtitle: 'Lower quality saves memory',
                            trailing: SegmentedButton<String>(
                              segments: const [
                                ButtonSegment(value: 'low', label: Text('LOW', style: TextStyle(fontSize: 10))),
                                ButtonSegment(value: 'medium', label: Text('MED', style: TextStyle(fontSize: 10))),
                                ButtonSegment(value: 'high', label: Text('HIGH', style: TextStyle(fontSize: 10))),
                              ],
                              selected: {settings.imageQuality},
                              onSelectionChanged: (v) => notifier.setImageQuality(v.first),
                              style: ButtonStyle(
                                backgroundColor: WidgetStateProperty.resolveWith((states) {
                                  if (states.contains(WidgetState.selected)) {
                                    return Theme.of(context).primaryColor.withValues(alpha: 0.3);
                                  }
                                  return Colors.white.withValues(alpha: 0.05);
                                }),
                                foregroundColor: WidgetStateProperty.all(Colors.white),
                                side: WidgetStateProperty.all(const BorderSide(color: Colors.white24)),
                              ),
                            ),
                          ),
                          const Divider(color: Colors.white12),
                          _settingsTile(
                            icon: Icons.cleaning_services,
                            title: 'Audio Cleanup',
                            subtitle: 'Auto-delete old recordings',
                            trailing: DropdownButton<int>(
                              value: settings.autoCleanupHours,
                              dropdownColor: const Color(0xFF1A1A1A),
                              underline: const SizedBox.shrink(),
                              items: const [
                                DropdownMenuItem(value: 0, child: Text('Never', style: TextStyle(color: Colors.white, fontSize: 13))),
                                DropdownMenuItem(value: 1, child: Text('1h', style: TextStyle(color: Colors.white, fontSize: 13))),
                                DropdownMenuItem(value: 6, child: Text('6h', style: TextStyle(color: Colors.white, fontSize: 13))),
                                DropdownMenuItem(value: 24, child: Text('24h', style: TextStyle(color: Colors.white, fontSize: 13))),
                                DropdownMenuItem(value: 168, child: Text('7d', style: TextStyle(color: Colors.white, fontSize: 13))),
                              ],
                              onChanged: (v) => v != null ? notifier.setAutoCleanupHours(v) : null,
                            ),
                          ),
                          const Divider(color: Colors.white12),

                          _sectionTitle(context, 'FEEDBACK & SUPPORT'),
                          _settingsTile(
                            icon: Icons.bug_report_outlined,
                            title: 'Send Feedback',
                            subtitle: 'Report a bug or suggest a feature',
                            trailing: const Icon(Icons.chevron_right, color: Colors.white38),
                            onTap: () => _sendFeedbackEmail(context, ref),
                          ),
                          const Divider(color: Colors.white12),

                          _sectionTitle(context, 'ABOUT'),
                          _settingsTile(
                            icon: Icons.shield_outlined,
                            title: 'Privacy Policy',
                            subtitle: 'How we handle your data',
                            trailing: const Icon(Icons.chevron_right,
                                color: Colors.white38),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      const PrivacyPolicyScreen()),
                            ),
                          ),
                          const Divider(color: Colors.white12),
                          FutureBuilder<PackageInfo>(
                            future: PackageInfo.fromPlatform(),
                            builder: (context, snapshot) {
                              final version = snapshot.hasData
                                  ? '${snapshot.data!.version} (Build ${snapshot.data!.buildNumber})'
                                  : 'Loading...';
                              return _settingsTile(
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
                                    backgroundColor:
                                        const Color(0xFF1A1A1A),
                                    title: Text('Reset Settings?',
                                        style: GoogleFonts.oswald(
                                            color: Colors.white)),
                                    content: const Text(
                                      'This will restore all settings to their defaults.',
                                      style:
                                          TextStyle(color: Colors.white70),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(ctx, false),
                                        child: const Text('CANCEL',
                                            style: TextStyle(
                                                color: Colors.white54)),
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
                              icon: const Icon(Icons.restore,
                                  color: Colors.white38, size: 18),
                              label: Text('Reset to Defaults',
                                  style: GoogleFonts.lato(
                                      color: Colors.white38,
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
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget trailing,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Reserve space for icon (40) + gap (16) = 56px
            // Give trailing at most 55% of remaining width
            final maxTrailingWidth = (constraints.maxWidth - 56) * 0.55;
            return Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: Colors.white54, size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: GoogleFonts.lato(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text(subtitle,
                          style: GoogleFonts.lato(
                              color: Colors.white38, fontSize: 12)),
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
    // Optionally grab user ID if they are logged in.
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
      path: 'support@huntingcalls.app', // Placeholder, developer can update this later
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
}
