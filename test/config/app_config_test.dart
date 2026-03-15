import 'package:flutter_test/flutter_test.dart';
import 'package:outcall/config/app_config.dart';

void main() {
  group('AppFlavor', () {
    test('has free and full values', () {
      expect(AppFlavor.values.length, 2);
      expect(AppFlavor.values, contains(AppFlavor.free));
      expect(AppFlavor.values, contains(AppFlavor.full));
    });
  });

  group('AppConfig', () {
    setUp(() {
      // Reset between tests by recreating
      AppConfig.create(
        flavor: AppFlavor.free,
        appName: 'OUTCALL Free',
      );
    });

    test('create initializes singleton', () {
      expect(AppConfig.instance, isNotNull);
      expect(AppConfig.instance.flavor, AppFlavor.free);
      expect(AppConfig.instance.appName, 'OUTCALL Free');
    });

    test('isFree returns true for free flavor', () {
      AppConfig.create(
        flavor: AppFlavor.free,
        appName: 'OUTCALL Free',
      );
      expect(AppConfig.instance.isFree, true);
      expect(AppConfig.instance.isFull, false);
    });

    test('isFull returns true for full flavor', () {
      AppConfig.create(
        flavor: AppFlavor.full,
        appName: 'OUTCALL Pro',
      );
      expect(AppConfig.instance.isFull, true);
      expect(AppConfig.instance.isFree, false);
    });

    test('feature flags disabled for free', () {
      AppConfig.create(flavor: AppFlavor.free, appName: 'Free');
      expect(AppConfig.instance.allowMap, false);
      expect(AppConfig.instance.allowSocial, false);
      expect(AppConfig.instance.allowLeaderboard, false);
    });

    test('feature flags enabled for full', () {
      AppConfig.create(flavor: AppFlavor.full, appName: 'Full');
      expect(AppConfig.instance.allowMap, true);
      expect(AppConfig.instance.allowSocial, true);
      expect(AppConfig.instance.allowLeaderboard, true);
    });

    test('supportEmail is correct', () {
      expect(AppConfig.supportEmail, 'BenchmarkAppsLLC@gmail.com');
    });

    test('apiBaseUrl is optional', () {
      AppConfig.create(
        flavor: AppFlavor.free,
        appName: 'Test',
        apiBaseUrl: 'https://api.example.com',
      );
      expect(AppConfig.instance.apiBaseUrl, 'https://api.example.com');
    });

    test('storeUrl is optional', () {
      AppConfig.create(
        flavor: AppFlavor.free,
        appName: 'Test',
        storeUrl: 'https://play.google.com/store/apps/details?id=com.example',
      );
      expect(AppConfig.instance.storeUrl, contains('play.google.com'));
    });

    test('create overwrites previous config', () {
      AppConfig.create(flavor: AppFlavor.free, appName: 'First');
      expect(AppConfig.instance.appName, 'First');
      AppConfig.create(flavor: AppFlavor.full, appName: 'Second');
      expect(AppConfig.instance.appName, 'Second');
      expect(AppConfig.instance.isFull, true);
    });
  });
}
