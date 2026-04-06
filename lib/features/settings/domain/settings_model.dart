import 'package:flutter/material.dart';
import 'package:outcall/core/theme/app_theme.dart';
import 'package:outcall/features/settings/domain/calibration_profile.dart';

/// Domain model for application settings.
class AppSettings {
  final AppTheme theme;
  final ThemeMode themeMode;
  final String distanceUnit; // 'imperial' | 'metric'
  final bool notificationsEnabled;
  final bool soundEffects;
  final bool hapticFeedback;
  final String imageQuality; // 'high' | 'medium' | 'low'
  final int autoCleanupHours;
  final CalibrationProfile calibration;
  final bool highContrast;

  const AppSettings({
    this.theme = AppTheme.classic,
    this.themeMode = ThemeMode.dark,
    this.distanceUnit = 'imperial',
    this.notificationsEnabled = true,
    this.soundEffects = true,
    this.hapticFeedback = true,
    this.imageQuality = 'high',
    this.autoCleanupHours = 24,
    this.calibration = const CalibrationProfile(),
    this.highContrast = false,
  });

  AppSettings copyWith({
    AppTheme? theme,
    ThemeMode? themeMode,
    String? distanceUnit,
    bool? notificationsEnabled,
    bool? soundEffects,
    bool? hapticFeedback,
    String? imageQuality,
    int? autoCleanupHours,
    CalibrationProfile? calibration,
    bool? highContrast,
  }) {
    return AppSettings(
      theme: theme ?? this.theme,
      themeMode: themeMode ?? this.themeMode,
      distanceUnit: distanceUnit ?? this.distanceUnit,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      soundEffects: soundEffects ?? this.soundEffects,
      hapticFeedback: hapticFeedback ?? this.hapticFeedback,
      imageQuality: imageQuality ?? this.imageQuality,
      autoCleanupHours: autoCleanupHours ?? this.autoCleanupHours,
      calibration: calibration ?? this.calibration,
      highContrast: highContrast ?? this.highContrast,
    );
  }

  Map<String, dynamic> toMap() => {
        'theme': theme.name,
        'themeMode': themeMode.name,
        'distanceUnit': distanceUnit,
        'notificationsEnabled': notificationsEnabled,
        'soundEffects': soundEffects,
        'hapticFeedback': hapticFeedback,
        'imageQuality': imageQuality,
        'autoCleanupHours': autoCleanupHours,
        'calibration': calibration.toMap(),
        'highContrast': highContrast,
      };

  factory AppSettings.fromMap(Map<String, dynamic> map) {
    return AppSettings(
      theme: AppTheme.values.firstWhere(
        (e) => e.name == map['theme'],
        orElse: () => map['darkMode'] == false ? AppTheme.classic : AppTheme.classic, // Fallback logic
      ),
      themeMode: ThemeMode.values.firstWhere(
        (e) => e.name == map['themeMode'],
        orElse: () => ThemeMode.dark,
      ),
      distanceUnit: map['distanceUnit'] as String? ?? 'imperial',
      notificationsEnabled: map['notificationsEnabled'] as bool? ?? true,
      soundEffects: map['soundEffects'] as bool? ?? true,
      hapticFeedback: map['hapticFeedback'] as bool? ?? true,
      imageQuality: map['imageQuality'] as String? ?? 'high',
      autoCleanupHours: map['autoCleanupHours'] as int? ?? 24,
      calibration: map['calibration'] != null
          ? CalibrationProfile.fromMap(Map<String, dynamic>.from(map['calibration']))
          : const CalibrationProfile(),
      highContrast: map['highContrast'] as bool? ?? false,
    );
  }
}
