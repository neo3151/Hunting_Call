
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:outcall/features/recording/domain/visualization_settings.dart';
import 'package:outcall/features/recording/presentation/widgets/live_visualizer.dart';
import 'package:outcall/features/library/domain/reference_call_model.dart';
import 'package:outcall/features/recording/presentation/controllers/recording_controller.dart';

import 'package:outcall/features/recording/domain/audio_sample.dart';

/// Live visualizer container with mode toggles and coaching overlay.
class RecorderVisualizerSection extends ConsumerWidget {
  final ReferenceCall selectedCall;
  final List<AudioSample> amplitudeBuffer;
  final bool isRecording;
  final bool isCountingDown;
  final double Function(List<double>?) computeRefAvg;
  final ({String text, Color color}) Function(double refAvg) getCoachingFeedback;

  const RecorderVisualizerSection({
    super.key,
    required this.selectedCall,
    required this.amplitudeBuffer,
    required this.isRecording,
    required this.isCountingDown,
    required this.computeRefAvg,
    required this.getCoachingFeedback,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vizSettings = ref.watch(visualizationSettingsProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Semantics(
            label: vizSettings.mode == VisualizationMode.waveform
                ? 'Live waveform visualizer'
                : 'Spectral sync visualizer',
            liveRegion: true,
            child: Container(
            height: 140,
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white10),
            ),
            child: Stack(
              children: [
                Builder(
                  builder: (context) {
                    ref.watch(amplitudeStreamProvider); // Trigger rebuild on amplitude change
                    return ExcludeSemantics(
                      child: LiveVisualizer(
                      activeSamples: amplitudeBuffer,
                      referencePattern: vizSettings.showReferenceOverlay ? selectedCall.waveform : null,
                      referenceSpectrogram: vizSettings.showReferenceOverlay ? selectedCall.spectrogram : null,
                      mode: vizSettings.mode,
                      color: (isRecording || isCountingDown) ? Colors.tealAccent : Colors.teal.withValues(alpha: 0.5),
                      isRecording: isRecording || isCountingDown,
                      referenceAvgAmplitude: computeRefAvg(selectedCall.waveform),
                      referenceDurationSec: selectedCall.idealDurationSec,
                    ),
                    );
                  },
                ),
                // Mode Toggles
                Positioned(
                  top: 4,
                  right: 4,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: () => ref.read(visualizationSettingsProvider.notifier).toggleMode(),
                        icon: Icon(
                          vizSettings.mode == VisualizationMode.waveform ? Icons.graphic_eq : Icons.bar_chart,
                          color: Colors.white54,
                          size: 18,
                        ),
                        tooltip: 'Switch View',
                      ),
                      IconButton(
                        onPressed: () => ref.read(visualizationSettingsProvider.notifier).toggleReferenceOverlay(),
                        icon: Icon(
                          Icons.layers,
                          color: vizSettings.showReferenceOverlay ? Colors.orangeAccent : Colors.white54,
                          size: 18,
                        ),
                        tooltip: 'Toggle Reference',
                      ),
                    ],
                  ),
                ),
                // Mode Label
                Positioned(
                  top: 8,
                  left: 12,
                  child: ExcludeSemantics(
                    child: Text(
                    vizSettings.mode == VisualizationMode.waveform ? 'WAVEFORM' : 'SPECTRAL SYNC',
                    style: GoogleFonts.oswald(color: Colors.white24, fontSize: 10, letterSpacing: 1),
                  ),
                  ),
                ),
              ],
            ),
          ),
          ),
        ),
        // Coaching feedback
        if (isRecording) Builder(
          builder: (context) {
            final refAvg = computeRefAvg(selectedCall.waveform);
            final feedback = getCoachingFeedback(refAvg);
            if (feedback.text.isEmpty) return const SizedBox.shrink();
            return Semantics(
              liveRegion: true,
              label: 'Coaching: ${feedback.text}',
              child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: GoogleFonts.oswald(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2.0,
                  color: feedback.color,
                ),
                child: Text(feedback.text),
              ),
            ),
            );
          },
        ),
      ],
    );
  }
}

/// Mic button with decorative rings and state-based appearance.
class RecorderMicButton extends StatelessWidget {
  final bool isRecording;
  final bool isCountingDown;
  final bool isProcessing;
  final int countdownValue;
  final Animation<double> pulseAnimation;
  final VoidCallback onPressed;

  const RecorderMicButton({
    super.key,
    required this.isRecording,
    required this.isCountingDown,
    required this.isProcessing,
    required this.countdownValue,
    required this.pulseAnimation,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 150,
      height: 150,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer decorative ring
          if (!isRecording && !isCountingDown && !isProcessing)
            ExcludeSemantics(
              child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.15),
                  width: 2,
                ),
              ),
            ),
            ),
          // Inner decorative ring
          if (!isRecording && !isCountingDown && !isProcessing)
            ExcludeSemantics(
              child: Container(
              width: 125,
              height: 125,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.25),
                  width: 2,
                ),
              ),
            ),
            ),
          if (isRecording)
            ScaleTransition(
              scale: pulseAnimation,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.red.withValues(alpha: 0.3), width: 4),
                ),
              ),
            ),
          if (isCountingDown)
            Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.orange.withValues(alpha: 0.5), width: 3),
              ),
            ),
          // The actual button
          Semantics(
            label: isProcessing
                ? 'Processing recording'
                : isCountingDown
                    ? 'Countdown $countdownValue'
                    : isRecording
                        ? 'Stop recording'
                        : 'Start recording',
            button: true,
            child: SizedBox(
            width: 90,
            height: 90,
            child: ElevatedButton(
              onPressed: (isCountingDown || isProcessing) ? null : onPressed,
              style: ElevatedButton.styleFrom(
                shape: const CircleBorder(),
                padding: EdgeInsets.zero,
                backgroundColor: isProcessing
                    ? Colors.grey.withValues(alpha: 0.8)
                    : isRecording
                        ? Colors.red.withValues(alpha: 0.8)
                        : isCountingDown
                            ? Colors.orange.withValues(alpha: 0.8)
                            : Theme.of(context).primaryColor,
                elevation: 8,
                shadowColor: (isProcessing ? Colors.grey : isRecording ? Colors.red : Theme.of(context).primaryColor).withValues(alpha: 0.4),
                side: BorderSide(color: Colors.white.withValues(alpha: 0.2), width: 2),
              ),
              child: isProcessing
                  ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 3)
                  : isCountingDown
                      ? Text(
                          countdownValue == 0 ? 'GO' : '$countdownValue',
                          style: GoogleFonts.oswald(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.white),
                        )
                      : Icon(isRecording ? Icons.stop : Icons.mic, color: Colors.white, size: 36),
            ),
          ),
          ),
        ],
      ),
    );
  }
}

/// Recording duration indicator badge.
class RecordingTimerBadge extends StatelessWidget {
  final String formattedDuration;

  const RecordingTimerBadge({super.key, required this.formattedDuration});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Recording time: $formattedDuration',
      liveRegion: true,
      child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const ExcludeSemantics(
            child: Icon(Icons.circle, color: Colors.red, size: 12),
          ),
          const SizedBox(width: 8),
          Text(
            formattedDuration,
            style: GoogleFonts.oswald(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    ),
    );
  }
}
