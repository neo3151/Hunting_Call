/// Seasonal/themed challenge configuration for daily challenges.
///
/// Themes cycle through curated lists of animal IDs for special weeks
/// (e.g., "Waterfowl Week", "Predator Month"). The daily challenge
/// controller can check if a seasonal theme is active and bias its
/// animal selection accordingly.
class SeasonalTheme {
  final String id;
  final String name;
  final String emoji;
  final String description;
  final DateTime startDate;
  final DateTime endDate;
  final List<String> animalIds;

  const SeasonalTheme({
    required this.id,
    required this.name,
    required this.emoji,
    required this.description,
    required this.startDate,
    required this.endDate,
    required this.animalIds,
  });

  bool get isActive {
    final now = DateTime.now();
    return now.isAfter(startDate) && now.isBefore(endDate);
  }

  /// Returns the number of days remaining in this theme, or 0 if expired.
  int get daysRemaining {
    final diff = endDate.difference(DateTime.now()).inDays;
    return diff > 0 ? diff : 0;
  }
}

/// Hardcoded seasonal themes — can later be migrated to Firestore remote config.
class SeasonalThemeService {
  static final List<SeasonalTheme> themes = [
    SeasonalTheme(
      id: 'waterfowl_week',
      name: 'Waterfowl Week',
      emoji: '🦆',
      description: 'Master your duck and goose calls this week!',
      startDate: DateTime(2026, 3, 10),
      endDate: DateTime(2026, 3, 17),
      animalIds: ['mallard_drake', 'mallard_hen', 'canada_goose', 'wood_duck', 'pintail'],
    ),
    SeasonalTheme(
      id: 'predator_month',
      name: 'Predator Month',
      emoji: '🐺',
      description: 'Hone your predator calls all month long.',
      startDate: DateTime(2026, 4, 1),
      endDate: DateTime(2026, 4, 30),
      animalIds: ['coyote_howl', 'coyote_bark', 'fox_distress', 'crow_call'],
    ),
    SeasonalTheme(
      id: 'elk_season',
      name: 'Elk Season Prep',
      emoji: '🦌',
      description: 'Get ready for the rut — perfect your elk calls!',
      startDate: DateTime(2026, 8, 15),
      endDate: DateTime(2026, 9, 15),
      animalIds: ['elk_bugle', 'elk_cow', 'elk_calf'],
    ),
    SeasonalTheme(
      id: 'turkey_spring',
      name: 'Spring Gobbler',
      emoji: '🦃',
      description: 'Spring turkey season is here — sharpen your yelps and clucks!',
      startDate: DateTime(2026, 3, 20),
      endDate: DateTime(2026, 5, 1),
      animalIds: ['turkey_gobble', 'turkey_yelp', 'turkey_cluck', 'turkey_purr'],
    ),
  ];

  /// Returns the currently active theme, if any.
  static SeasonalTheme? get activeTheme {
    try {
      return themes.firstWhere((t) => t.isActive);
    } catch (_) {
      return null;
    }
  }

  /// Returns true if there's an active seasonal theme.
  static bool get hasActiveTheme => activeTheme != null;
}
