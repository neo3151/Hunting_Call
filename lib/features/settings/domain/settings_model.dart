/// Domain model for application settings.
class AppSettings {
  final bool darkMode;
  final String distanceUnit; // 'imperial' | 'metric'
  final bool notificationsEnabled;
  final bool soundEffects;
  final bool hapticFeedback;
  final String imageQuality; // 'high' | 'medium' | 'low'
  final int autoCleanupHours;

  const AppSettings({
    this.darkMode = true,
    this.distanceUnit = 'imperial',
    this.notificationsEnabled = true,
    this.soundEffects = true,
    this.hapticFeedback = true,
    this.imageQuality = 'high',
    this.autoCleanupHours = 24,
  });

  AppSettings copyWith({
    bool? darkMode,
    String? distanceUnit,
    bool? notificationsEnabled,
    bool? soundEffects,
    bool? hapticFeedback,
    String? imageQuality,
    int? autoCleanupHours,
  }) {
    return AppSettings(
      darkMode: darkMode ?? this.darkMode,
      distanceUnit: distanceUnit ?? this.distanceUnit,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      soundEffects: soundEffects ?? this.soundEffects,
      hapticFeedback: hapticFeedback ?? this.hapticFeedback,
      imageQuality: imageQuality ?? this.imageQuality,
      autoCleanupHours: autoCleanupHours ?? this.autoCleanupHours,
    );
  }

  Map<String, dynamic> toMap() => {
        'darkMode': darkMode,
        'distanceUnit': distanceUnit,
        'notificationsEnabled': notificationsEnabled,
        'soundEffects': soundEffects,
        'hapticFeedback': hapticFeedback,
        'imageQuality': imageQuality,
        'autoCleanupHours': autoCleanupHours,
      };

  factory AppSettings.fromMap(Map<String, dynamic> map) {
    return AppSettings(
      darkMode: map['darkMode'] as bool? ?? true,
      distanceUnit: map['distanceUnit'] as String? ?? 'imperial',
      notificationsEnabled: map['notificationsEnabled'] as bool? ?? true,
      soundEffects: map['soundEffects'] as bool? ?? true,
      hapticFeedback: map['hapticFeedback'] as bool? ?? true,
      imageQuality: map['imageQuality'] as String? ?? 'high',
      autoCleanupHours: map['autoCleanupHours'] as int? ?? 24,
    );
  }
}
