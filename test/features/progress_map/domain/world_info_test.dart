import 'package:flutter_test/flutter_test.dart';
import 'package:outcall/features/progress_map/domain/world_info.dart';

void main() {
  group('WorldInfo', () {
    test('has 5 worlds defined', () {
      expect(worlds.length, 5);
    });

    test('each world has a unique name', () {
      final names = worlds.map((w) => w.name).toSet();
      expect(names.length, worlds.length);
    });

    test('world names match expected roster', () {
      final names = worlds.map((w) => w.name).toList();
      expect(names, contains('MARSHLANDS'));
      expect(names, contains('THE RIDGE'));
      expect(names, contains('HOWL CANYON'));
      expect(names, contains('SHADOW PEAK'));
      expect(names, contains('TIMBER HOLLOW'));
    });

    test('each world maps to a unique category', () {
      final categories = worlds.map((w) => w.category).toSet();
      expect(categories.length, worlds.length);
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
      expect(getAnimalEmoji('Northern Pintail'), '🦆');
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
