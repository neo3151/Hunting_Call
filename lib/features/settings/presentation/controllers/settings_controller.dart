import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hunting_calls_perfection/di_providers.dart';
import 'package:hunting_calls_perfection/core/theme/app_theme.dart';
import 'package:hunting_calls_perfection/features/settings/data/settings_repository.dart';
import 'package:hunting_calls_perfection/features/settings/domain/settings_model.dart';
import 'package:hunting_calls_perfection/core/utils/app_logger.dart';

// ─── Repository Provider ────────────────────────────────────────────────────

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  final storage = ref.watch(simpleStorageProvider);
  return SettingsRepository(storage);
});

// ─── Controller ─────────────────────────────────────────────────────────────

class SettingsNotifier extends AsyncNotifier<AppSettings> {
  @override
  Future<AppSettings> build() async {
    final repo = ref.read(settingsRepositoryProvider);
    return repo.loadSettings();
  }

  Future<void> updateSetting(AppSettings Function(AppSettings) updater) async {
    final current = state.valueOrNull ?? const AppSettings();
    final updated = updater(current);
    state = AsyncValue.data(updated);

    try {
      await ref.read(settingsRepositoryProvider).saveSettings(updated);
    } catch (e) {
      AppLogger.d('Settings save error: $e');
    }
  }

  Future<void> setTheme(AppTheme theme) async {
    await updateSetting((s) => s.copyWith(theme: theme));
  }

  Future<void> setDistanceUnit(String value) async {
    await updateSetting((s) => s.copyWith(distanceUnit: value));
  }

  Future<void> setNotificationsEnabled(bool value) async {
    await updateSetting((s) => s.copyWith(notificationsEnabled: value));
  }

  Future<void> setSoundEffects(bool value) async {
    await updateSetting((s) => s.copyWith(soundEffects: value));
  }

  Future<void> setHapticFeedback(bool value) async {
    await updateSetting((s) => s.copyWith(hapticFeedback: value));
  }

  Future<void> setImageQuality(String value) async {
    await updateSetting((s) => s.copyWith(imageQuality: value));
  }

  Future<void> setAutoCleanupHours(int value) async {
    await updateSetting((s) => s.copyWith(autoCleanupHours: value));
  }

  Future<void> resetToDefaults() async {
    const defaults = AppSettings();
    state = const AsyncValue.data(defaults);
    await ref.read(settingsRepositoryProvider).saveSettings(defaults);
  }
}

final settingsNotifierProvider =
    AsyncNotifierProvider<SettingsNotifier, AppSettings>(() {
  return SettingsNotifier();
});
