import 'package:flutter_riverpod/flutter_riverpod.dart';

/// State for the visualizer (high frequency updates)
class VisualizerState {
  final List<double> amplitudes;

  const VisualizerState({
    this.amplitudes = const [],
  });

  VisualizerState copyWith({
    List<double>? amplitudes,
  }) {
    return VisualizerState(
      amplitudes: amplitudes ?? this.amplitudes,
    );
  }
}

class VisualizerNotifier extends Notifier<VisualizerState> {
  @override
  VisualizerState build() {
    return const VisualizerState();
  }

  void addAmplitude(double amplitude) {
    final current = state.amplitudes;
    // Keep last 50 points
    final newAmplitudes = [...current, amplitude];
    if (newAmplitudes.length > 50) {
      newAmplitudes.removeAt(0);
    }
    state = state.copyWith(amplitudes: newAmplitudes);
  }

  void reset() {
    state = const VisualizerState(amplitudes: []);
  }
}

final visualizerProvider = NotifierProvider<VisualizerNotifier, VisualizerState>(() {
  return VisualizerNotifier();
});
