import 'package:hunting_calls_perfection/core/theme/app_theme.dart';

/// Domain model for application settings.
class AppSettings {
  final AppTheme theme;
  final String distanceUnit; // 'imperial' | 'metric'
  final bool notificationsEnabled;
  final bool soundEffects;
  final bool hapticFeedback;
  final String imageQuality; // 'high' | 'medium' | 'low'
  final int autoCleanupHours;

  const AppSettings({
    this.theme = AppTheme.classic,
    this.distanceUnit = 'imperial',
    this.notificationsEnabled = true,
    this.soundEffects = true,
    this.hapticFeedback = true,
    this.imageQuality = 'high',
    this.autoCleanupHours = 24,
  });

  AppSettings copyWith({
    AppTheme? theme,
    String? distanceUnit,
    bool? notificationsEnabled,
    bool? soundEffects,
    bool? hapticFeedback,
    String? imageQuality,
    int? autoCleanupHours,
  }) {
    return AppSettings(
      theme: theme ?? this.theme,
      distanceUnit: distanceUnit ?? this.distanceUnit,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      soundEffects: soundEffects ?? this.soundEffects,
      hapticFeedback: hapticFeedback ?? this.hapticFeedback,
      imageQuality: imageQuality ?? this.imageQuality,
      autoCleanupHours: autoCleanupHours ?? this.autoCleanupHours,
    );
  }

  Map<String, dynamic> toMap() => {
        'theme': theme.name,
        'distanceUnit': distanceUnit,
        'notificationsEnabled': notificationsEnabled,
        'soundEffects': soundEffects,
        'hapticFeedback': hapticFeedback,
        'imageQuality': imageQuality,
        'autoCleanupHours': autoCleanupHours,
      };

  factory AppSettings.fromMap(Map<String, dynamic> map) {
    return AppSettings(
      theme: AppTheme.values.firstWhere(
        (e) => e.name == map['theme'],
        orElse: () => map['darkMode'] == false ? AppTheme.classic : AppTheme.classic, // Fallback logic
      ),
      distanceUnit: map['distanceUnit'] as String? ?? 'imperial',
      notificationsEnabled: map['notificationsEnabled'] as bool? ?? true,
      soundEffects: map['soundEffects'] as bool? ?? true,
      hapticFeedback: map['hapticFeedback'] as bool? ?? true,
      imageQuality: map['imageQuality'] as String? ?? 'high',
      autoCleanupHours: map['autoCleanupHours'] as int? ?? 24,
    );
  }
}
