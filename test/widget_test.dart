import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:outcall/di_providers.dart';
import 'package:outcall/features/settings/presentation/controllers/settings_controller.dart';
void main() {
  group('Platform Bootstrap', () {

    test('Riverpod providers initialize in mock environment', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final container = ProviderContainer(
        overrides: [
          platformEnvironmentProvider.overrideWithValue(PlatformEnvironment(
            isFirebaseEnabled: false,
            isDesktop: true,
            useMocks: true,
            sharedPreferences: prefs,
          )),
        ],
      );
      addTearDown(container.dispose);

      // PlatformEnvironment should be accessible
      final env = container.read(platformEnvironmentProvider);
      expect(env.isFirebaseEnabled, isFalse);
      expect(env.useMocks, isTrue);

      // Settings should load defaults without error
      final settings = await container.read(settingsNotifierProvider.future);
      expect(settings.soundEffects, isTrue); // default
      expect(settings.calibration.isCalibrated, isFalse); // default
    });
  });
}
