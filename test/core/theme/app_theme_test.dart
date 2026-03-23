import 'package:flutter_test/flutter_test.dart';
import 'package:outcall/core/theme/app_theme.dart';

void main() {
  group('AppTheme', () {
    test('has 4 theme variants', () {
      expect(AppTheme.values.length, 4);
    });

    test('classic, midnight, forest, hunter all exist', () {
      expect(AppTheme.values, contains(AppTheme.classic));
      expect(AppTheme.values, contains(AppTheme.midnight));
      expect(AppTheme.values, contains(AppTheme.forest));
      expect(AppTheme.values, contains(AppTheme.hunter));
    });

    test('name property returns correct string', () {
      expect(AppTheme.classic.name, 'classic');
      expect(AppTheme.midnight.name, 'midnight');
      expect(AppTheme.forest.name, 'forest');
      expect(AppTheme.hunter.name, 'hunter');
    });

    test('can be looked up by name', () {
      expect(
        AppTheme.values.firstWhere((t) => t.name == 'forest'),
        AppTheme.forest,
      );
    });

    test('index values are sequential', () {
      for (int i = 0; i < AppTheme.values.length; i++) {
        expect(AppTheme.values[i].index, i);
      }
    });
  });
}
