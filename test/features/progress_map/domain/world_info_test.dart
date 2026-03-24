import 'package:flutter_test/flutter_test.dart';
import 'package:outcall/features/progress_map/domain/world_info.dart';

void main() {
  group('WorldInfo', () {
    test('has 8 worlds defined', () {
      expect(worlds.length, 8);
    });

    test('each world has a unique name', () {
      final names = worlds.map((w) => w.name).toSet();
      expect(names.length, worlds.length);
    });

    test('world names match expected roster', () {
      final names = worlds.map((w) => w.name).toList();
      expect(names, contains('MARSHLANDS'));
      expect(names, contains('TIDEWATER BAY'));
      expect(names, contains('BAYOU CROSSING'));
      expect(names, contains('FLYWAY DELTA'));
      expect(names, contains('THE RIDGE'));
      expect(names, contains('HOWL CANYON'));
      expect(names, contains('SHADOW PEAK'));
      expect(names, contains('TIMBER HOLLOW'));
    });

    test('each world has either animalNames or categories', () {
      for (final w in worlds) {
        expect(
          w.animalNames.isNotEmpty || w.categories.isNotEmpty,
          isTrue,
          reason: '${w.name} should have animalNames or categories',
        );
      }
    });
  });

  group('NodeState', () {
    test('has expected values', () {
      expect(NodeState.values.length, 4);
      expect(NodeState.values, contains(NodeState.mastered));
      expect(NodeState.values, contains(NodeState.current));
      expect(NodeState.values, contains(NodeState.available));
      expect(NodeState.values, contains(NodeState.locked));
    });
  });

  group('getAnimalEmoji', () {
    test('returns duck emoji for waterfowl', () {
      expect(getAnimalEmoji('Mallard Duck'), '🦆');
      expect(getAnimalEmoji('Green-winged Teal'), '🦆');
      expect(getAnimalEmoji('Canvasback'), '🦆');
    });

    test('returns deer emoji for big game', () {
      expect(getAnimalEmoji('Whitetail Deer'), '🦌');
      expect(getAnimalEmoji('Mule Deer'), '🦌');
      expect(getAnimalEmoji('Bull Elk'), '🦌');
      expect(getAnimalEmoji('Fallow Deer'), '🦌');
    });

    test('returns wolf emoji for canines', () {
      expect(getAnimalEmoji('Coyote Howl'), '🐺');
      expect(getAnimalEmoji('Gray Wolf'), '🐺');
    });

    test('returns cat emoji for big cats', () {
      expect(getAnimalEmoji('Bobcat Growl'), '🐆');
      expect(getAnimalEmoji('Mountain Cougar'), '🐆');
    });

    test('returns lion emoji for lion', () {
      expect(getAnimalEmoji('Lion Scream'), '🦁');
    });

    test('returns turkey emoji for turkey', () {
      expect(getAnimalEmoji('Wild Turkey Gobble'), '🦃');
    });

    test('returns bird emoji for land birds', () {
      expect(getAnimalEmoji('Ringneck Pheasant'), '🐦');
      expect(getAnimalEmoji('Mourning Dove'), '🐦');
      expect(getAnimalEmoji('Bobwhite Quail'), '🐦');
    });

    test('returns hog emoji for hogs', () {
      expect(getAnimalEmoji('Wild Hog Squeal'), '🐗');
    });

    test('returns sparkle emoji for awebo', () {
      expect(getAnimalEmoji('Awebo'), '✨');
    });

    test('returns default target emoji for unknown animals', () {
      expect(getAnimalEmoji('Unknown Animal'), '🎯');
      expect(getAnimalEmoji('Alien Beast'), '🎯');
    });

    test('is case-insensitive', () {
      expect(getAnimalEmoji('MALLARD DUCK'), '🦆');
      expect(getAnimalEmoji('coyote howl'), '🐺');
    });
  });
}
