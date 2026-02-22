import 'package:hunting_calls_perfection/core/theme/app_theme.dart';
import 'package:hunting_calls_perfection/core/services/simple_storage.dart';
import 'package:hunting_calls_perfection/features/settings/domain/settings_model.dart';

/// Persists [AppSettings] using ISimpleStorage.
class SettingsRepository {
  static const _prefix = 'app_settings_';
  final ISimpleStorage _storage;

  SettingsRepository(this._storage);

  Future<AppSettings> loadSettings() async {
    final themeName = await _storage.getString('${_prefix}theme') ?? AppTheme.classic.name;
    final theme = AppTheme.values.firstWhere(
      (e) => e.name == themeName,
      orElse: () => AppTheme.classic,
    );

    return AppSettings(
      theme: theme,
      distanceUnit: await _storage.getString('${_prefix}distanceUnit') ?? 'imperial',
      notificationsEnabled: await _storage.getBool('${_prefix}notificationsEnabled') ?? true,
      soundEffects: await _storage.getBool('${_prefix}soundEffects') ?? true,
      hapticFeedback: await _storage.getBool('${_prefix}hapticFeedback') ?? true,
      imageQuality: await _storage.getString('${_prefix}imageQuality') ?? 'high',
      autoCleanupHours: await _storage.getInt('${_prefix}autoCleanupHours') ?? 24,
    );
  }

  Future<void> saveSettings(AppSettings settings) async {
    await _storage.setString('${_prefix}theme', settings.theme.name);
    await _storage.setString('${_prefix}distanceUnit', settings.distanceUnit);
    await _storage.setBool('${_prefix}notificationsEnabled', settings.notificationsEnabled);
    await _storage.setBool('${_prefix}soundEffects', settings.soundEffects);
    await _storage.setBool('${_prefix}hapticFeedback', settings.hapticFeedback);
    await _storage.setString('${_prefix}imageQuality', settings.imageQuality);
    await _storage.setInt('${_prefix}autoCleanupHours', settings.autoCleanupHours);
  }

  Future<void> clearSettings() async {
    for (final key in [
      'theme',
      'distanceUnit',
      'notificationsEnabled',
      'soundEffects',
      'hapticFeedback',
    ]) {
      await _storage.remove('$_prefix$key');
    }
  }
}
