import 'package:flutter_test/flutter_test.dart';
import 'package:outcall/core/utils/spam_filter.dart';

void main() {
  group('SpamFilter', () {
    group('isSuspiciousEmail', () {
      test('detects bot-farm pattern: firstname.lastname.NNNNN@gmail.com', () {
        expect(SpamFilter.isSuspiciousEmail('vernagomez.70967@gmail.com'), isTrue);
        expect(SpamFilter.isSuspiciousEmail('bryantbarrett.60557@gmail.com'), isTrue);
        expect(SpamFilter.isSuspiciousEmail('lenadelgado.25110@gmail.com'), isTrue);
        expect(SpamFilter.isSuspiciousEmail('latoyariley.22096@gmail.com'), isTrue);
        expect(SpamFilter.isSuspiciousEmail('tinamorton.83921@gmail.com'), isTrue);
        expect(SpamFilter.isSuspiciousEmail('janellaharrell.41739@gmail.com'), isTrue);
      });

      test('detects blocked test domains', () {
        expect(SpamFilter.isSuspiciousEmail('test@test.com'), isTrue);
        expect(SpamFilter.isSuspiciousEmail('test@test.test'), isTrue);
        expect(SpamFilter.isSuspiciousEmail('foo@example.com'), isTrue);
        expect(SpamFilter.isSuspiciousEmail('bar@mailinator.com'), isTrue);
        expect(SpamFilter.isSuspiciousEmail('baz@yopmail.com'), isTrue);
      });

      test('allows legitimate emails', () {
        expect(SpamFilter.isSuspiciousEmail('pongownsyou@gmail.com'), isFalse);
        expect(SpamFilter.isSuspiciousEmail('benchmarkappsllc@gmail.com'), isFalse);
        expect(SpamFilter.isSuspiciousEmail('mgarcia3159@gmail.com'), isFalse);
        expect(SpamFilter.isSuspiciousEmail('masonjoem@gmail.com'), isFalse);
        expect(SpamFilter.isSuspiciousEmail('captzackk@gmail.com'), isFalse);
        expect(SpamFilter.isSuspiciousEmail('emilyclass2025@gmail.com'), isFalse);
        expect(SpamFilter.isSuspiciousEmail('nomindsboy@gmail.com'), isFalse);
      });

      test('handles null and empty emails', () {
        expect(SpamFilter.isSuspiciousEmail(null), isFalse);
        expect(SpamFilter.isSuspiciousEmail(''), isFalse);
      });

      test('is case-insensitive', () {
        expect(SpamFilter.isSuspiciousEmail('VERNAgomez.70967@Gmail.Com'), isTrue);
        expect(SpamFilter.isSuspiciousEmail('TEST@TEST.COM'), isTrue);
      });
    });

    group('isSuspiciousProfile', () {
      test('flags profiles with suspicious emails', () {
        expect(
          SpamFilter.isSuspiciousProfile(
            email: 'vernagomez.70967@gmail.com',
            displayName: 'Verna Gomez',
            createdAt: DateTime.now(),
            historyCount: 5,
          ),
          isTrue,
        );
      });

      test('flags old ghost accounts (no email, no activity)', () {
        expect(
          SpamFilter.isSuspiciousProfile(
            email: null,
            displayName: null,
            createdAt: DateTime.now().subtract(const Duration(days: 30)),
            historyCount: 0,
          ),
          isTrue,
        );
      });

      test('allows new anonymous accounts (under 7 days)', () {
        expect(
          SpamFilter.isSuspiciousProfile(
            email: null,
            displayName: null,
            createdAt: DateTime.now().subtract(const Duration(days: 2)),
            historyCount: 0,
          ),
          isFalse,
        );
      });

      test('allows legitimate profiles with real emails', () {
        expect(
          SpamFilter.isSuspiciousProfile(
            email: 'mgarcia3159@gmail.com',
            displayName: 'MGarcia3159',
            createdAt: DateTime.now().subtract(const Duration(days: 60)),
            historyCount: 10,
          ),
          isFalse,
        );
      });
    });

    group('getSuspiciousReason', () {
      test('returns reason for bot-farm email', () {
        final reason = SpamFilter.getSuspiciousReason('vernagomez.70967@gmail.com');
        expect(reason, contains('bot-farm'));
      });

      test('returns reason for blocked domain', () {
        final reason = SpamFilter.getSuspiciousReason('test@mailinator.com');
        expect(reason, contains('blocked domain'));
      });

      test('returns null for legitimate email', () {
        expect(SpamFilter.getSuspiciousReason('pongownsyou@gmail.com'), isNull);
      });

      test('returns null for null/empty input', () {
        expect(SpamFilter.getSuspiciousReason(null), isNull);
        expect(SpamFilter.getSuspiciousReason(''), isNull);
      });
    });
  });
}
