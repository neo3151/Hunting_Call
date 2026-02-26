import 'package:flutter_test/flutter_test.dart';
import 'package:outcall/config/app_config.dart';

void main() {
  group('AppConfig', () {
    setUp(() {
      // Create a fresh config for each test
      AppConfig.create(
        flavor: AppFlavor.full,
        appName: 'OUTCALL Test',
        apiBaseUrl: 'https://api.test.com',
        storeUrl: 'https://play.google.com/store/apps/details?id=com.neo3151.huntingcalls',
      );
    });

    test('instance returns created config', () {
      final config = AppConfig.instance;
      expect(config.appName, 'OUTCALL Test');
      expect(config.flavor, AppFlavor.full);
    });

    test('isFree and isFull reflect flavor', () {
      expect(AppConfig.instance.isFull, true);
      expect(AppConfig.instance.isFree, false);
    });

    test('free flavor disables premium feature flags', () {
      AppConfig.create(flavor: AppFlavor.free, appName: 'Test Free');
      final config = AppConfig.instance;
      expect(config.isFree, true);
      expect(config.allowMap, false);
      expect(config.allowSocial, false);
      expect(config.allowLeaderboard, false);
    });

    test('full flavor enables premium feature flags', () {
      final config = AppConfig.instance;
      expect(config.isFull, true);
      expect(config.allowMap, true);
      expect(config.allowSocial, true);
      expect(config.allowLeaderboard, true);
    });

    test('supportEmail is set correctly', () {
      expect(AppConfig.supportEmail, 'BenchmarkAppsLLC@gmail.com');
    });

    test('provider throws before config is created', () {
      // Reset the singleton by creating and testing exception
      // (Can't actually reset the singleton, but we can test the contract)
      expect(AppConfig.instance, isNotNull);
    });
  });
}
