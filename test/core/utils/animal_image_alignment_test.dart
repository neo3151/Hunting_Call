import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:outcall/core/utils/animal_image_alignment.dart';

void main() {
  group('AnimalImageAlignment', () {
    test('known image returns custom alignment', () {
      final align = AnimalImageAlignment.forImage('assets/images/animals/elk.webp');
      expect(align, isNot(Alignment.center));
      expect(align.y, greaterThan(0)); // elk is shifted up (positive y)
    });

    test('barred_owl returns slightly north alignment', () {
      final align = AnimalImageAlignment.forImage('barred_owl.webp');
      expect(align.y, lessThan(0)); // north = negative y
    });

    test('unknown image returns Alignment.center', () {
      final align = AnimalImageAlignment.forImage('nonexistent_animal.png');
      expect(align, Alignment.center);
    });

    test('full path extracts filename correctly', () {
      final align = AnimalImageAlignment.forImage('assets/images/animals/turkey.webp');
      expect(align, isNot(Alignment.center)); // turkey should be in the map
    });

    test('all mapped images have non-null alignments', () {
      final testImages = [
        'barred_owl.webp', 'black_bear.webp', 'cottontail_rabbit.webp',
        'coyote.webp', 'elk.webp', 'crow.webp', 'fallow_deer.webp',
        'great_horned_owl.webp', 'mourning_dove.webp', 'quail.webp',
        'specklebelly_goose.webp', 'turkey.webp', 'willow_ptarmigan.webp',
        'woodcock.webp',
      ];
      for (final img in testImages) {
        final align = AnimalImageAlignment.forImage(img);
        expect(align, isNotNull, reason: '$img should have alignment');
      }
    });

    test('x alignment is always centered (all images use 0.0 x)', () {
      final testImages = [
        'barred_owl.webp', 'elk.webp', 'turkey.webp', 'coyote.webp',
      ];
      for (final img in testImages) {
        final align = AnimalImageAlignment.forImage(img);
        expect(align.x, 0.0, reason: '$img should be centered horizontally');
      }
    });

    test('empty string returns center', () {
      expect(AnimalImageAlignment.forImage(''), Alignment.center);
    });
  });
}
