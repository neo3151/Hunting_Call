import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:outcall/features/recording/domain/recording_mode.dart';

void main() {
  group('RecordingMode', () {
    test('has two values', () {
      expect(RecordingMode.values.length, 2);
    });

    test('quickMatch and expert are distinct', () {
      expect(RecordingMode.quickMatch, isNot(equals(RecordingMode.expert)));
    });
  });

  group('RecordingModeNotifier', () {
    test('defaults to quickMatch', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(container.read(recordingModeProvider), RecordingMode.quickMatch);
    });

    test('setMode changes to expert', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(recordingModeProvider.notifier).setMode(RecordingMode.expert);
      expect(container.read(recordingModeProvider), RecordingMode.expert);
    });

    test('setMode changes back to quickMatch', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(recordingModeProvider.notifier).setMode(RecordingMode.expert);
      container.read(recordingModeProvider.notifier).setMode(RecordingMode.quickMatch);
      expect(container.read(recordingModeProvider), RecordingMode.quickMatch);
    });

    test('toggle switches from quickMatch to expert', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(recordingModeProvider.notifier).toggle();
      expect(container.read(recordingModeProvider), RecordingMode.expert);
    });

    test('toggle switches back from expert to quickMatch', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(recordingModeProvider.notifier).toggle();
      container.read(recordingModeProvider.notifier).toggle();
      expect(container.read(recordingModeProvider), RecordingMode.quickMatch);
    });
  });
}
