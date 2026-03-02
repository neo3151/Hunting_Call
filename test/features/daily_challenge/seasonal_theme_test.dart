import 'package:flutter_test/flutter_test.dart';
import 'package:outcall/features/daily_challenge/domain/seasonal_theme.dart';

void main() {
  group('SeasonalTheme', () {
    test('isActive returns true when now is within date range', () {
      final theme = SeasonalTheme(
        id: 'test',
        name: 'Test Theme',
        emoji: '🧪',
        description: 'Testing',
        startDate: DateTime.now().subtract(const Duration(days: 1)),
        endDate: DateTime.now().add(const Duration(days: 5)),
        animalIds: ['elk_bugle'],
      );
      expect(theme.isActive, true);
    });

    test('isActive returns false when dates are in the past', () {
      final theme = SeasonalTheme(
        id: 'past',
        name: 'Past Theme',
        emoji: '⏰',
        description: 'Expired',
        startDate: DateTime(2020, 1, 1),
        endDate: DateTime(2020, 1, 31),
        animalIds: ['elk_bugle'],
      );
      expect(theme.isActive, false);
    });

    test('isActive returns false when dates are in the future', () {
      final theme = SeasonalTheme(
        id: 'future',
        name: 'Future Theme',
        emoji: '🔮',
        description: 'Not yet',
        startDate: DateTime(2099, 1, 1),
        endDate: DateTime(2099, 12, 31),
        animalIds: ['elk_bugle'],
      );
      expect(theme.isActive, false);
    });

    test('daysRemaining returns positive days for active theme', () {
      final theme = SeasonalTheme(
        id: 'active',
        name: 'Active',
        emoji: '✅',
        description: 'Active theme',
        startDate: DateTime.now().subtract(const Duration(days: 1)),
        endDate: DateTime.now().add(const Duration(days: 10)),
        animalIds: ['elk_bugle'],
      );
      expect(theme.daysRemaining, greaterThanOrEqualTo(9));
      expect(theme.daysRemaining, lessThanOrEqualTo(10));
    });

    test('daysRemaining returns 0 for expired theme', () {
      final theme = SeasonalTheme(
        id: 'expired',
        name: 'Expired',
        emoji: '💀',
        description: 'Done',
        startDate: DateTime(2020, 1, 1),
        endDate: DateTime(2020, 1, 31),
        animalIds: [],
      );
      expect(theme.daysRemaining, 0);
    });
  });

  group('SeasonalThemeService', () {
    test('themes list is not empty', () {
      expect(SeasonalThemeService.themes, isNotEmpty);
    });

    test('all themes have unique IDs', () {
      final ids = SeasonalThemeService.themes.map((t) => t.id).toList();
      expect(ids.toSet().length, ids.length);
    });

    test('all themes have non-empty animalIds', () {
      for (final t in SeasonalThemeService.themes) {
        expect(t.animalIds.isNotEmpty, true, reason: '${t.id} has no animal IDs');
      }
    });

    test('all themes have valid date ranges (start < end)', () {
      for (final t in SeasonalThemeService.themes) {
        expect(t.startDate.isBefore(t.endDate), true,
            reason: '${t.id} has start >= end');
      }
    });

    test('hasActiveTheme is consistent with activeTheme', () {
      expect(SeasonalThemeService.hasActiveTheme,
          SeasonalThemeService.activeTheme != null);
    });
  });
}
