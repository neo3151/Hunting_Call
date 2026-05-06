import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:outcall/core/services/connectivity/connectivity_provider.dart';

void main() {
  group('isOfflineProvider', () {
    test('reports offline when connectivity results are empty', () async {
      final container = ProviderContainer(overrides: [
        connectivityStreamProvider.overrideWith(
          (ref) => Stream.value(<ConnectivityResult>[]),
        ),
      ]);
      addTearDown(container.dispose);

      // listen() keeps the reactive chain alive so Riverpod propagates stream events
      container.listen(isOfflineProvider, (_, __) {});
      await Future.delayed(Duration.zero);
      expect(container.read(isOfflineProvider), true);
    });

    test('reports offline when only ConnectivityResult.none', () async {
      final container = ProviderContainer(overrides: [
        connectivityStreamProvider.overrideWith(
          (ref) => Stream.value([ConnectivityResult.none]),
        ),
      ]);
      addTearDown(container.dispose);

      container.listen(isOfflineProvider, (_, __) {});
      await Future.delayed(Duration.zero);
      expect(container.read(isOfflineProvider), true);
    });

    test('reports online when wifi is available', () async {
      final container = ProviderContainer(overrides: [
        connectivityStreamProvider.overrideWith(
          (ref) => Stream.value([ConnectivityResult.wifi]),
        ),
      ]);
      addTearDown(container.dispose);

      container.listen(isOfflineProvider, (_, __) {});
      await Future.delayed(Duration.zero);
      expect(container.read(isOfflineProvider), false);
    });

    test('reports online when mobile is available', () async {
      final container = ProviderContainer(overrides: [
        connectivityStreamProvider.overrideWith(
          (ref) => Stream.value([ConnectivityResult.mobile]),
        ),
      ]);
      addTearDown(container.dispose);

      container.listen(isOfflineProvider, (_, __) {});
      await Future.delayed(Duration.zero);
      expect(container.read(isOfflineProvider), false);
    });

    test('reports online when mixed results include a real connection', () async {
      final container = ProviderContainer(overrides: [
        connectivityStreamProvider.overrideWith(
          (ref) => Stream.value([ConnectivityResult.none, ConnectivityResult.wifi]),
        ),
      ]);
      addTearDown(container.dispose);

      container.listen(isOfflineProvider, (_, __) {});
      await Future.delayed(Duration.zero);
      expect(container.read(isOfflineProvider), false);
    });

    test('reports offline on stream error (safe default)', () {
      // Override the stream provider directly with an error AsyncValue to bypass
      // stream delivery timing — we're testing the mapping logic, not stream mechanics.
      final container = ProviderContainer(overrides: [
        connectivityStreamProvider.overrideWithValue(
          AsyncValue.error(Exception('Network check failed'), StackTrace.empty),
        ),
      ]);
      addTearDown(container.dispose);

      expect(container.read(isOfflineProvider), true);
    });

    test('reports online while loading (avoids flashing offline)', () async {
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
