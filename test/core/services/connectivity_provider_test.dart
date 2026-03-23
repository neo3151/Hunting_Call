import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:outcall/core/services/connectivity/connectivity_provider.dart';

void main() {
  group('isOfflineProvider', () {
    test('reports offline when connectivity results are empty', () {
      final container = ProviderContainer(overrides: [
        connectivityStreamProvider.overrideWith(
          (ref) => Stream.value(<ConnectivityResult>[]),
        ),
      ]);
      addTearDown(container.dispose);

      // Give the stream time to emit
      expect(container.read(isOfflineProvider), true);
    });

    test('reports offline when only ConnectivityResult.none', () {
      final container = ProviderContainer(overrides: [
        connectivityStreamProvider.overrideWith(
          (ref) => Stream.value([ConnectivityResult.none]),
        ),
      ]);
      addTearDown(container.dispose);

      expect(container.read(isOfflineProvider), true);
    });

    test('reports online when wifi is available', () {
      final container = ProviderContainer(overrides: [
        connectivityStreamProvider.overrideWith(
          (ref) => Stream.value([ConnectivityResult.wifi]),
        ),
      ]);
      addTearDown(container.dispose);

      expect(container.read(isOfflineProvider), false);
    });

    test('reports online when mobile is available', () {
      final container = ProviderContainer(overrides: [
        connectivityStreamProvider.overrideWith(
          (ref) => Stream.value([ConnectivityResult.mobile]),
        ),
      ]);
      addTearDown(container.dispose);

      expect(container.read(isOfflineProvider), false);
    });

    test('reports online when mixed results include a real connection', () {
      final container = ProviderContainer(overrides: [
        connectivityStreamProvider.overrideWith(
          (ref) => Stream.value([ConnectivityResult.none, ConnectivityResult.wifi]),
        ),
      ]);
      addTearDown(container.dispose);

      expect(container.read(isOfflineProvider), false);
    });

    test('reports offline on stream error (safe default)', () {
      final container = ProviderContainer(overrides: [
        connectivityStreamProvider.overrideWith(
          (ref) => Stream.error(Exception('Network check failed')),
        ),
      ]);
      addTearDown(container.dispose);

      expect(container.read(isOfflineProvider), true);
    });

    test('reports online while loading (avoids flashing offline)', () {
      final container = ProviderContainer(overrides: [
        connectivityStreamProvider.overrideWith(
          // Stream that never emits — stays in loading state
          (ref) => const Stream.empty(),
        ),
      ]);
      addTearDown(container.dispose);

      expect(container.read(isOfflineProvider), false);
    });
  });
}
