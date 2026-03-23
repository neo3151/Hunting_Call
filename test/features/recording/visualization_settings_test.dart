import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:outcall/features/recording/domain/visualization_settings.dart';

void main() {
  group('VisualizationMode', () {
    test('has two values', () {
      expect(VisualizationMode.values.length, 2);
    });
  });

  group('VisualizationSettings', () {
    test('defaults to waveform with reference overlay', () {
      const settings = VisualizationSettings();
      expect(settings.mode, VisualizationMode.waveform);
      expect(settings.showReferenceOverlay, true);
    });

    test('copyWith preserves unchanged fields', () {
      const settings = VisualizationSettings();
      final copy = settings.copyWith(mode: VisualizationMode.spectrogram);
      expect(copy.mode, VisualizationMode.spectrogram);
      expect(copy.showReferenceOverlay, true); // preserved
    });

    test('copyWith can change overlay', () {
      const settings = VisualizationSettings();
      final copy = settings.copyWith(showReferenceOverlay: false);
      expect(copy.showReferenceOverlay, false);
      expect(copy.mode, VisualizationMode.waveform); // preserved
    });

    test('copyWith with no args returns equivalent settings', () {
      const settings = VisualizationSettings();
      final copy = settings.copyWith();
      expect(copy.mode, settings.mode);
      expect(copy.showReferenceOverlay, settings.showReferenceOverlay);
    });
  });

  group('VisualizationSettingsNotifier', () {
    test('defaults to waveform mode', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final settings = container.read(visualizationSettingsProvider);
      expect(settings.mode, VisualizationMode.waveform);
    });

    test('toggleMode switches waveform → spectrogram', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(visualizationSettingsProvider.notifier).toggleMode();
      expect(container.read(visualizationSettingsProvider).mode, VisualizationMode.spectrogram);
    });

    test('toggleMode switches spectrogram → waveform', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(visualizationSettingsProvider.notifier).toggleMode();
      container.read(visualizationSettingsProvider.notifier).toggleMode();
      expect(container.read(visualizationSettingsProvider).mode, VisualizationMode.waveform);
    });

    test('toggleReferenceOverlay flips the flag', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(container.read(visualizationSettingsProvider).showReferenceOverlay, true);
      container.read(visualizationSettingsProvider.notifier).toggleReferenceOverlay();
      expect(container.read(visualizationSettingsProvider).showReferenceOverlay, false);
      container.read(visualizationSettingsProvider.notifier).toggleReferenceOverlay();
      expect(container.read(visualizationSettingsProvider).showReferenceOverlay, true);
    });
  });
}
