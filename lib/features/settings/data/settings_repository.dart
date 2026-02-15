import 'package:shared_preferences/shared_preferences.dart';
import '../domain/settings_model.dart';

/// Persists [AppSettings] using SharedPreferences.
class SettingsRepository {
  static const _prefix = 'app_settings_';

  Future<AppSettings> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return AppSettings(
      darkMode: prefs.getBool('${_prefix}darkMode') ?? true,
      distanceUnit: prefs.getString('${_prefix}distanceUnit') ?? 'imperial',
      notificationsEnabled:
          prefs.getBool('${_prefix}notificationsEnabled') ?? true,
      soundEffects: prefs.getBool('${_prefix}soundEffects') ?? true,
      hapticFeedback: prefs.getBool('${_prefix}hapticFeedback') ?? true,
    );
  }

  Future<void> saveSettings(AppSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('${_prefix}darkMode', settings.darkMode);
    await prefs.setString('${_prefix}distanceUnit', settings.distanceUnit);
    await prefs.setBool(
        '${_prefix}notificationsEnabled', settings.notificationsEnabled);
    await prefs.setBool('${_prefix}soundEffects', settings.soundEffects);
    await prefs.setBool('${_prefix}hapticFeedback', settings.hapticFeedback);
  }

  Future<void> clearSettings() async {
    final prefs = await SharedPreferences.getInstance();
    for (final key in [
      'darkMode',
      'distanceUnit',
      'notificationsEnabled',
      'soundEffects',
      'hapticFeedback',
    ]) {
      await prefs.remove('$_prefix$key');
    }
  }
}
