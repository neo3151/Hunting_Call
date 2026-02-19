
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum VisualizationMode {
  waveform,
  spectrogram,
}

class VisualizationSettings {
  final VisualizationMode mode;
  final bool showReferenceOverlay;

  const VisualizationSettings({
    this.mode = VisualizationMode.waveform,
    this.showReferenceOverlay = true,
  });

  VisualizationSettings copyWith({
    VisualizationMode? mode,
    bool? showReferenceOverlay,
  }) {
    return VisualizationSettings(
      mode: mode ?? this.mode,
      showReferenceOverlay: showReferenceOverlay ?? this.showReferenceOverlay,
    );
  }
}

class VisualizationSettingsNotifier extends Notifier<VisualizationSettings> {
  @override
  VisualizationSettings build() {
    return const VisualizationSettings();
  }

  void toggleMode() {
    state = state.copyWith(
      mode: state.mode == VisualizationMode.waveform
          ? VisualizationMode.spectrogram
          : VisualizationMode.waveform,
    );
  }

  void toggleReferenceOverlay() {
    state = state.copyWith(
      showReferenceOverlay: !state.showReferenceOverlay,
    );
  }
}

final visualizationSettingsProvider =
    NotifierProvider<VisualizationSettingsNotifier, VisualizationSettings>(() {
  return VisualizationSettingsNotifier();
});
