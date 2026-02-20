import 'package:shared_preferences/shared_preferences.dart';
import 'package:hunting_calls_perfection/core/theme/app_theme.dart';
import '../domain/settings_model.dart';

/// Persists [AppSettings] using SharedPreferences.
class SettingsRepository {
  static const _prefix = 'app_settings_';

  Future<AppSettings> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final themeName = prefs.getString('${_prefix}theme') ?? AppTheme.classic.name;
    final theme = AppTheme.values.firstWhere(
      (e) => e.name == themeName,
      orElse: () => AppTheme.classic,
    );

    return AppSettings(
      theme: theme,
      distanceUnit: prefs.getString('${_prefix}distanceUnit') ?? 'imperial',
      notificationsEnabled:
          prefs.getBool('${_prefix}notificationsEnabled') ?? true,
      soundEffects: prefs.getBool('${_prefix}soundEffects') ?? true,
      hapticFeedback: prefs.getBool('${_prefix}hapticFeedback') ?? true,
      imageQuality: prefs.getString('${_prefix}imageQuality') ?? 'high',
      autoCleanupHours: prefs.getInt('${_prefix}autoCleanupHours') ?? 24,
    );
  }

  Future<void> saveSettings(AppSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('${_prefix}theme', settings.theme.name);
    await prefs.setString('${_prefix}distanceUnit', settings.distanceUnit);
    await prefs.setBool(
        '${_prefix}notificationsEnabled', settings.notificationsEnabled);
    await prefs.setBool('${_prefix}soundEffects', settings.soundEffects);
    await prefs.setBool('${_prefix}hapticFeedback', settings.hapticFeedback);
    await prefs.setString('${_prefix}imageQuality', settings.imageQuality);
    await prefs.setInt('${_prefix}autoCleanupHours', settings.autoCleanupHours);
  }

  Future<void> clearSettings() async {
    final prefs = await SharedPreferences.getInstance();
    for (final key in [
      'theme',
      'distanceUnit',
      'notificationsEnabled',
      'soundEffects',
      'hapticFeedback',
    ]) {
      await prefs.remove('$_prefix$key');
    }
  }
}
