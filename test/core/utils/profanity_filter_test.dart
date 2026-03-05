import 'package:flutter_test/flutter_test.dart';
import 'package:outcall/core/utils/profanity_filter.dart';

void main() {
  group('ProfanityFilter', () {
    group('containsProfanity — basic', () {
      test('returns false for null or empty input', () {
        expect(ProfanityFilter.containsProfanity(null), isFalse);
        expect(ProfanityFilter.containsProfanity(''), isFalse);
      });

      test('returns false for clean names', () {
        expect(ProfanityFilter.containsProfanity('Hunter'), isFalse);
        expect(ProfanityFilter.containsProfanity('Sam Bornfriend'), isFalse);
        expect(ProfanityFilter.containsProfanity('John Doe'), isFalse);
        expect(ProfanityFilter.containsProfanity('Emily'), isFalse);
      });

      test('detects explicit profanity', () {
        expect(ProfanityFilter.containsProfanity('fuck'), isTrue);
        expect(ProfanityFilter.containsProfanity('shit'), isTrue);
        expect(ProfanityFilter.containsProfanity('asshole'), isTrue);
      });

      test('detects profanity case-insensitively', () {
        expect(ProfanityFilter.containsProfanity('FUCK'), isTrue);
        expect(ProfanityFilter.containsProfanity('Shit'), isTrue);
        expect(ProfanityFilter.containsProfanity('AsSHoLe'), isTrue);
      });

      test('detects racial slurs', () {
        expect(ProfanityFilter.containsProfanity('nigger'), isTrue);
        expect(ProfanityFilter.containsProfanity('nigga'), isTrue);
      });

      test('detects hate terms', () {
        expect(ProfanityFilter.containsProfanity('hitler'), isTrue);
        expect(ProfanityFilter.containsProfanity('nazi'), isTrue);
        expect(ProfanityFilter.containsProfanity('kkk'), isTrue);
      });

      test('detects combined offensive terms', () {
        expect(ProfanityFilter.containsProfanity('niggerhitler'), isTrue);
      });

      test('detects misspelling evasion', () {
        expect(ProfanityFilter.containsProfanity('hilter'), isTrue);
      });
    });

    group('containsProfanity — leet-speak', () {
      test('detects number substitutions', () {
        expect(ProfanityFilter.containsProfanity('sh1t'), isTrue);
        expect(ProfanityFilter.containsProfanity('a55'), isTrue);
        expect(ProfanityFilter.containsProfanity('f4g'), isTrue);
      });

      test('detects symbol substitutions', () {
        expect(ProfanityFilter.containsProfanity('@sshole'), isTrue);
        expect(ProfanityFilter.containsProfanity('\$hit'), isTrue);
      });

      test('detects spaced-out evasion', () {
        expect(ProfanityFilter.containsProfanity('f.u.c.k'), isTrue);
        expect(ProfanityFilter.containsProfanity('s_h_i_t'), isTrue);
        expect(ProfanityFilter.containsProfanity('n-i-g-g-e-r'), isTrue);
      });
    });

    group('containsProfanity — homoglyphs', () {
      test('detects Cyrillic lookalikes', () {
        // 'а' is Cyrillic 'а' (U+0430), not Latin 'a'
        expect(ProfanityFilter.containsProfanity('fuc\u043A'), isTrue); // Cyrillic к
        expect(ProfanityFilter.containsProfanity('h\u0456tler'), isTrue); // Cyrillic і
      });
    });

    group('containsProfanity — repeated characters', () {
      test('detects repeated character evasion', () {
        expect(ProfanityFilter.containsProfanity('fuuuuuck'), isTrue);
        expect(ProfanityFilter.containsProfanity('shiiiit'), isTrue);
        expect(ProfanityFilter.containsProfanity('niggggger'), isTrue);
      });
    });

    group('containsProfanity — reversed text', () {
      test('detects reversed profanity', () {
        expect(ProfanityFilter.containsProfanity('kcuf'), isTrue); // fuck reversed
        expect(ProfanityFilter.containsProfanity('tihs'), isTrue); // shit reversed
      });
    });

    group('containsProfanity — multi-language', () {
      test('detects Spanish profanity', () {
        expect(ProfanityFilter.containsProfanity('puta'), isTrue);
        expect(ProfanityFilter.containsProfanity('mierda'), isTrue);
        expect(ProfanityFilter.containsProfanity('pendejo'), isTrue);
      });

      test('detects French profanity', () {
        expect(ProfanityFilter.containsProfanity('putain'), isTrue);
        expect(ProfanityFilter.containsProfanity('merde'), isTrue);
      });

      test('detects German profanity', () {
        expect(ProfanityFilter.containsProfanity('schlampe'), isTrue);
        expect(ProfanityFilter.containsProfanity('arschloch'), isTrue);
      });
    });

    group('containsProfanity — false-positive whitelist', () {
      test('allows whitelisted words containing blocked substrings', () {
        expect(ProfanityFilter.containsProfanity('assassin'), isFalse);
        expect(ProfanityFilter.containsProfanity('Dickens'), isFalse);
        expect(ProfanityFilter.containsProfanity('cockatoo'), isFalse);
        expect(ProfanityFilter.containsProfanity('Scunthorpe'), isFalse);
        expect(ProfanityFilter.containsProfanity('grape'), isFalse);
        expect(ProfanityFilter.containsProfanity('hello'), isFalse);
        expect(ProfanityFilter.containsProfanity('title'), isFalse);
        expect(ProfanityFilter.containsProfanity('night'), isFalse);
        expect(ProfanityFilter.containsProfanity('cocktail'), isFalse);
      });
    });

    group('cleanName', () {
      test('returns the name if it is clean', () {
        expect(ProfanityFilter.cleanName('Hunter'), equals('Hunter'));
        expect(ProfanityFilter.cleanName('Sam'), equals('Sam'));
      });

      test('returns fallback for profane names', () {
        expect(ProfanityFilter.cleanName('hitler'), equals('Hunter'));
        expect(ProfanityFilter.cleanName('niggerhitler'), equals('Hunter'));
      });

      test('supports custom fallback', () {
        expect(
          ProfanityFilter.cleanName('hitler', fallback: 'Anonymous'),
          equals('Anonymous'),
        );
      });
    });

    group('getFirstMatch', () {
      test('returns null for clean input', () {
        expect(ProfanityFilter.getFirstMatch('Hunter'), isNull);
        expect(ProfanityFilter.getFirstMatch(null), isNull);
      });

      test('returns the matched term for direct matches', () {
        expect(ProfanityFilter.getFirstMatch('hitler'), isNotNull);
        expect(ProfanityFilter.getFirstMatch('nigger'), isNotNull);
      });

      test('returns reversed annotation for reversed text', () {
        final match = ProfanityFilter.getFirstMatch('kcuf');
        expect(match, isNotNull);
        expect(match, contains('reversed'));
      });
    });

    group('loadRemoteTerms', () {
      test('detects dynamically loaded terms', () {
        ProfanityFilter.loadRemoteTerms(['custombadword']);
        expect(ProfanityFilter.containsProfanity('custombadword'), isTrue);
      });
    });
  });
}
