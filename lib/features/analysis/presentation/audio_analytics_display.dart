import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../domain/audio_analysis_model.dart';
import 'widgets/analytics_metric_card.dart';
import 'widgets/harmonics_display.dart';
import 'widgets/spectral_centroid_graph.dart';
import 'widgets/pitch_track_graph.dart';

/// Widget to display comprehensive audio analytics.
///
/// Composed from [AnalyticsMetricCard], [HarmonicsDisplay],
/// [PitchTrackGraph], and [SpectralCentroidGraph] widgets.
class AudioAnalyticsDisplay extends StatelessWidget {
  final AudioAnalysis analysis;

  const AudioAnalyticsDisplay({super.key, required this.analysis});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('PITCH ANALYSIS'),
        _metricGrid([
          AnalyticsMetricCard(label: 'Dominant Frequency', value: analysis.dominantFrequencyHz, unit: 'Hz'),
          AnalyticsMetricCard(label: 'Average Frequency', value: analysis.averageFrequencyHz, unit: 'Hz'),
          AnalyticsMetricCard(label: 'Pitch Stability', value: analysis.pitchStability, unit: '%'),
        ]),

        if (analysis.pitchTrack.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text('Pitch Development',
              style: GoogleFonts.lato(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 8),
          PitchTrackGraph(pitchTrack: analysis.pitchTrack),
        ],

        const SizedBox(height: 24),

        _sectionHeader('VOLUME ANALYSIS'),
        _metricGrid([
          AnalyticsMetricCard(label: 'Average Volume', value: analysis.averageVolume * 100, unit: '%'),
          AnalyticsMetricCard(label: 'Peak Volume', value: analysis.peakVolume * 100, unit: '%'),
          AnalyticsMetricCard(label: 'Consistency', value: analysis.volumeConsistency, unit: '%'),
        ]),

        const SizedBox(height: 24),

        _sectionHeader('TONE ANALYSIS'),
        _metricGrid([
          AnalyticsMetricCard(label: 'Tone Clarity', value: analysis.toneClarity, unit: '%'),
          AnalyticsMetricCard(label: 'Harmonic Richness', value: analysis.harmonicRichness, unit: '%'),
          AnalyticsMetricCard(label: 'Call Quality', value: analysis.callQualityScore, unit: '%'),
        ]),

        if (analysis.harmonics.isNotEmpty) ...[
          const SizedBox(height: 12),
          HarmonicsDisplay(harmonics: analysis.harmonics),
        ],

        const SizedBox(height: 24),

        _sectionHeader('TIMBRE ANALYSIS'),
        _metricGrid([
          AnalyticsMetricCard(label: 'Brightness', value: analysis.brightness, unit: '%'),
          AnalyticsMetricCard(label: 'Warmth', value: analysis.warmth, unit: '%'),
          AnalyticsMetricCard(label: 'Nasality', value: analysis.nasality, unit: '%'),
        ]),

        if (analysis.spectralCentroid.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text('Timbre Dynamics (Spectral Centroid)',
              style: GoogleFonts.lato(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 8),
          SpectralCentroidGraph(centroids: analysis.spectralCentroid),
        ],

        const SizedBox(height: 24),

        _sectionHeader('DURATION ANALYSIS'),
        _metricGrid([
          AnalyticsMetricCard(label: 'Total Duration', value: analysis.totalDurationSec, unit: 's'),
          AnalyticsMetricCard(label: 'Active Duration', value: analysis.activeDurationSec, unit: 's'),
          AnalyticsMetricCard(label: 'Silence Duration', value: analysis.silenceDurationSec, unit: 's'),
        ]),

        if (analysis.isPulsedCall) ...[
          const SizedBox(height: 24),
          _sectionHeader('RHYTHM ANALYSIS'),
          _metricGrid([
            AnalyticsMetricCard(label: 'Tempo', value: analysis.tempo, unit: 'BPM'),
            AnalyticsMetricCard(label: 'Pulses Detected', value: analysis.pulseTimes.length.toDouble(), unit: ''),
            AnalyticsMetricCard(label: 'Rhythm Regularity', value: analysis.rhythmRegularity, unit: '%'),
          ]),
        ],
      ],
    );
  }

  // ─── Shared Section Layout Helpers ──────────────────────────────────────

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 20,
            decoration: BoxDecoration(
              color: Colors.greenAccent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: GoogleFonts.oswald(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricGrid(List<Widget> metrics) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: metrics,
    );
  }
}
