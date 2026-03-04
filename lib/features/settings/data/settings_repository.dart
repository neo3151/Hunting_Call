import 'package:outcall/core/theme/app_theme.dart';
import 'package:outcall/core/services/simple_storage.dart';
import 'package:outcall/features/settings/domain/calibration_profile.dart';
import 'package:outcall/features/settings/domain/settings_model.dart';

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
      calibration: await _loadCalibration(),
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
    await _saveCalibration(settings.calibration);
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
    // Also clear calibration keys
    for (final key in ['cal_scoreOffset', 'cal_micSensitivity', 'cal_noiseFloorLevel', 'cal_calibratedAt']) {
      await _storage.remove('$_prefix$key');
    }
  }

  // ─── Calibration helpers ─────────────────────────────────────────────

  static const _calPrefix = 'app_settings_cal_';

  Future<CalibrationProfile> _loadCalibration() async {
    final offset = await _storage.getDouble('${_calPrefix}scoreOffset');
    final sensitivity = await _storage.getDouble('${_calPrefix}micSensitivity');
    final noiseFloor = await _storage.getDouble('${_calPrefix}noiseFloorLevel');
    final calibratedAtStr = await _storage.getString('${_calPrefix}calibratedAt');

    return CalibrationProfile(
      scoreOffset: offset ?? 0.0,
      micSensitivity: sensitivity ?? 1.0,
      noiseFloorLevel: noiseFloor ?? 0.0,
      calibratedAt: calibratedAtStr != null ? DateTime.tryParse(calibratedAtStr) : null,
    );
  }

  Future<void> _saveCalibration(CalibrationProfile cal) async {
    await _storage.setDouble('${_calPrefix}scoreOffset', cal.scoreOffset);
    await _storage.setDouble('${_calPrefix}micSensitivity', cal.micSensitivity);
    await _storage.setDouble('${_calPrefix}noiseFloorLevel', cal.noiseFloorLevel);
    if (cal.calibratedAt != null) {
      await _storage.setString('${_calPrefix}calibratedAt', cal.calibratedAt!.toIso8601String());
    }
  }
}
