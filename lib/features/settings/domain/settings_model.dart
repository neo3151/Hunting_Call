/// Domain model for application settings.
class AppSettings {
  final bool darkMode;
  final String distanceUnit; // 'imperial' | 'metric'
  final bool notificationsEnabled;
  final bool soundEffects;
  final bool hapticFeedback;

  const AppSettings({
    this.darkMode = true,
    this.distanceUnit = 'imperial',
    this.notificationsEnabled = true,
    this.soundEffects = true,
    this.hapticFeedback = true,
  });

  AppSettings copyWith({
    bool? darkMode,
    String? distanceUnit,
    bool? notificationsEnabled,
    bool? soundEffects,
    bool? hapticFeedback,
  }) {
    return AppSettings(
      darkMode: darkMode ?? this.darkMode,
      distanceUnit: distanceUnit ?? this.distanceUnit,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      soundEffects: soundEffects ?? this.soundEffects,
      hapticFeedback: hapticFeedback ?? this.hapticFeedback,
    );
  }

  Map<String, dynamic> toMap() => {
        'darkMode': darkMode,
        'distanceUnit': distanceUnit,
        'notificationsEnabled': notificationsEnabled,
        'soundEffects': soundEffects,
        'hapticFeedback': hapticFeedback,
      };

  factory AppSettings.fromMap(Map<String, dynamic> map) {
    return AppSettings(
      darkMode: map['darkMode'] as bool? ?? true,
      distanceUnit: map['distanceUnit'] as String? ?? 'imperial',
      notificationsEnabled: map['notificationsEnabled'] as bool? ?? true,
      soundEffects: map['soundEffects'] as bool? ?? true,
      hapticFeedback: map['hapticFeedback'] as bool? ?? true,
    );
  }
}
