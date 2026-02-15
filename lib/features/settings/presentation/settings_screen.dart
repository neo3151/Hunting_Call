import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/widgets/background_wrapper.dart';
import 'controllers/settings_controller.dart';
import 'privacy_policy_screen.dart';

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
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: Color(0xFF81C784)),
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
                          _sectionTitle('APPEARANCE'),
                          _settingsTile(
                            icon: Icons.dark_mode,
                            title: 'Dark Mode',
                            subtitle: 'Use dark theme throughout the app',
                            trailing: Switch(
                              value: settings.darkMode,
                              onChanged: notifier.setDarkMode,
                              activeColor: const Color(0xFF81C784),
                            ),
                          ),
                          const Divider(color: Colors.white12),

                          _sectionTitle('PREFERENCES'),
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
                                    return const Color(0xFF81C784)
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
                              activeColor: const Color(0xFF81C784),
                            ),
                          ),
                          const Divider(color: Colors.white12),

                          _sectionTitle('AUDIO & HAPTICS'),
                          _settingsTile(
                            icon: Icons.volume_up_outlined,
                            title: 'Sound Effects',
                            subtitle: 'UI interaction sounds',
                            trailing: Switch(
                              value: settings.soundEffects,
                              onChanged: notifier.setSoundEffects,
                              activeColor: const Color(0xFF81C784),
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
                              activeColor: const Color(0xFF81C784),
                            ),
                          ),
                          const Divider(color: Colors.white12),

                          _sectionTitle('ABOUT'),
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
                          _settingsTile(
                            icon: Icons.info_outline,
                            title: 'App Version',
                            subtitle: '1.3.0 (Build 4)',
                            trailing: const SizedBox.shrink(),
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
                                        const Color(0xFF1B3B24),
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

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 12),
      child: Text(
        title,
        style: GoogleFonts.oswald(
          color: const Color(0xFF81C784),
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
        child: Row(
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
            trailing,
          ],
        ),
      ),
    );
  }
}
