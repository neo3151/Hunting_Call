import 'dart:io';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:outcall/core/utils/friendly_errors.dart';

void main() {
  group('FriendlyErrorFormatter', () {
    test('null error returns squirrel fallback', () {
      expect(FriendlyErrorFormatter.format(null), contains('squirrels'));
    });

    test('SocketException returns coffee break message', () {
      const error = SocketException('Connection refused');
      final msg = FriendlyErrorFormatter.format(error);
      expect(msg, contains('coffee break'));
      expect(msg, contains('☕'));
    });

    test('string with "network" returns coffee break', () {
      final msg = FriendlyErrorFormatter.format('NetworkError');
      expect(msg, contains('coffee break'));
    });

    test('string with "socket" returns coffee break', () {
      final msg = FriendlyErrorFormatter.format('socket connection failed');
      expect(msg, contains('connection'));
    });

    test('TimeoutException returns carrier pigeon', () {
      final error = TimeoutException('Request timed out');
      final msg = FriendlyErrorFormatter.format(error);
      expect(msg, contains('pigeon'));
      expect(msg, contains('🐦'));
    });

    test('string with "timeout" returns carrier pigeon', () {
      final msg = FriendlyErrorFormatter.format('Connection timeout');
      expect(msg, contains('pigeon'));
    });

    test('PlatformException returns gears message', () {
      final error = PlatformException(code: 'ERROR', message: 'Platform crash');
      final msg = FriendlyErrorFormatter.format(error);
      expect(msg, contains('gears'));
      expect(msg, contains('⚙️'));
    });

    test('FormatException returns map message', () {
      const error = FormatException('Bad format');
      final msg = FriendlyErrorFormatter.format(error);
      expect(msg, contains('map'));
      expect(msg, contains('🗺️'));
    });

    test('permission error returns key message', () {
      final msg = FriendlyErrorFormatter.format('Permission denied');
      expect(msg, contains('key'));
      expect(msg, contains('🗝️'));
    });

    test('unknown error returns wild error fallback', () {
      final msg = FriendlyErrorFormatter.format('Some random error abc123');
      expect(msg, contains('wild error'));
      expect(msg, contains('🦌'));
    });

    test('xmlhttprequest error returns network message', () {
      final msg = FriendlyErrorFormatter.format('XMLHttpRequest error');
      expect(msg, contains('coffee break'));
    });
  });
}
