import 'package:flutter_test/flutter_test.dart';
import 'package:outcall/core/utils/input_sanitizer.dart';

void main() {
  group('InputSanitizer.sanitizeName', () {
    test('trims whitespace', () {
      expect(InputSanitizer.sanitizeName('  John  '), 'John');
    });

    test('removes control characters', () {
      expect(InputSanitizer.sanitizeName('Jo\x00hn\x01'), 'John');
    });

    test('strips HTML tags', () {
      expect(InputSanitizer.sanitizeName('<script>alert("xss")</script>John'), 'alert("xss")John');
    });

    test('truncates to maxNameLength', () {
      final longName = 'A' * 100;
      final result = InputSanitizer.sanitizeName(longName);
      expect(result.length, InputSanitizer.maxNameLength);
    });

    test('preserves valid Unicode characters', () {
      expect(InputSanitizer.sanitizeName('Jöhn Dœ'), 'Jöhn Dœ');
    });

    test('preserves emojis', () {
      expect(InputSanitizer.sanitizeName('Hunter 🦌'), 'Hunter 🦌');
    });

    test('handles empty string', () {
      expect(InputSanitizer.sanitizeName(''), '');
    });

    test('handles whitespace-only string', () {
      expect(InputSanitizer.sanitizeName('   '), '');
    });

    test('removes nested HTML tags', () {
      expect(InputSanitizer.sanitizeName('<b><i>Bold</i></b>'), 'Bold');
    });
  });

  group('InputSanitizer.sanitizeFreeText', () {
    test('trims and strips tags', () {
      expect(InputSanitizer.sanitizeFreeText('  <p>Hello</p>  '), 'Hello');
    });

    test('truncates to maxFeedbackLength', () {
      final longText = 'B' * 1000;
      final result = InputSanitizer.sanitizeFreeText(longText);
      expect(result.length, InputSanitizer.maxFeedbackLength);
    });

    test('preserves newlines and tabs', () {
      expect(InputSanitizer.sanitizeFreeText('Line1\nLine2\tTabbed'), 'Line1\nLine2\tTabbed');
    });
  });

  group('InputSanitizer.isValidEmail', () {
    test('accepts valid emails', () {
      expect(InputSanitizer.isValidEmail('user@example.com'), isTrue);
      expect(InputSanitizer.isValidEmail('user.name+tag@domain.co'), isTrue);
      expect(InputSanitizer.isValidEmail('a@b.cd'), isTrue);
    });

    test('rejects invalid emails', () {
      expect(InputSanitizer.isValidEmail(''), isFalse);
      expect(InputSanitizer.isValidEmail('not-an-email'), isFalse);
      expect(InputSanitizer.isValidEmail('@missing-user.com'), isFalse);
      expect(InputSanitizer.isValidEmail('user@'), isFalse);
      expect(InputSanitizer.isValidEmail('user@.com'), isFalse);
    });

    test('trims whitespace before validating', () {
      expect(InputSanitizer.isValidEmail('  user@example.com  '), isTrue);
    });
  });
}
