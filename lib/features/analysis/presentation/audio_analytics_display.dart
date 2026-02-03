import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../domain/audio_analysis_model.dart';

/// Widget to display comprehensive audio analytics
class AudioAnalyticsDisplay extends StatelessWidget {
  final AudioAnalysis analysis;
  
  const AudioAnalyticsDisplay({super.key, required this.analysis});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader("PITCH ANALYSIS"),
        _buildMetricGrid([
          _buildMetric("Dominant Frequency", analysis.dominantFrequencyHz, "Hz"),
          _buildMetric("Average Frequency", analysis.averageFrequencyHz, "Hz"),
          _buildMetric("Pitch Stability", analysis.pitchStability, "%"),
        ]),
        
        const SizedBox(height: 24),
        
        _buildSectionHeader("VOLUME ANALYSIS"),
        _buildMetricGrid([
          _buildMetric("Average Volume", analysis.averageVolume * 100, "%"),
          _buildMetric("Peak Volume", analysis.peakVolume * 100, "%"),
          _buildMetric("Consistency", analysis.volumeConsistency, "%"),
        ]),
        
        const SizedBox(height: 24),
        
        _buildSectionHeader("TONE ANALYSIS"),
        _buildMetricGrid([
          _buildMetric("Tone Clarity", analysis.toneClarity, "%"),
          _buildMetric("Harmonic Richness", analysis.harmonicRichness, "%"),
          _buildMetric("Call Quality", analysis.callQualityScore, "%"),
        ]),
        
        if (analysis.harmonics.isNotEmpty) ...[
          const SizedBox(height: 12),
          _buildHarmonicsDisplay(analysis.harmonics),
        ],
        
        const SizedBox(height: 24),
        
        _buildSectionHeader("TIMBRE ANALYSIS"),
        _buildMetricGrid([
          _buildMetric("Brightness", analysis.brightness, "%"),
          _buildMetric("Warmth", analysis.warmth, "%"),
          _buildMetric("Nasality", analysis.nasality, "%"),
        ]),
        
        const SizedBox(height: 24),
        
        _buildSectionHeader("DURATION ANALYSIS"),
        _buildMetricGrid([
          _buildMetric("Total Duration", analysis.totalDurationSec, "s"),
          _buildMetric("Active Duration", analysis.activeDurationSec, "s"),
          _buildMetric("Silence Duration", analysis.silenceDurationSec, "s"),
        ]),
        
        if (analysis.isPulsedCall) ...[
          const SizedBox(height: 24),
          _buildSectionHeader("RHYTHM ANALYSIS"),
          _buildMetricGrid([
            _buildMetric("Tempo", analysis.tempo, "BPM"),
            _buildMetric("Pulses Detected", analysis.pulseTimes.length.toDouble(), ""),
            _buildMetric("Rhythm Regularity", analysis.rhythmRegularity, "%"),
          ]),
        ],
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
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

  Widget _buildMetricGrid(List<Widget> metrics) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: metrics,
    );
  }

  Widget _buildMetric(String label, double value, String unit) {
    Color color = _getColorForValue(value, unit);
    
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          width: 160,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.lato(
                  color: Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _formatValue(value),
                    style: GoogleFonts.oswald(
                      color: color,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (unit.isNotEmpty) ...[
                    const SizedBox(width: 4),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Text(
                        unit,
                        style: GoogleFonts.lato(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: _normalizeForProgress(value, unit),
                  minHeight: 4,
                  backgroundColor: Colors.white.withValues(alpha: 0.1),
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHarmonicsDisplay(Map<String, double> harmonics) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Detected Harmonics",
                style: GoogleFonts.lato(
                  color: Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: harmonics.entries.map((e) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.greenAccent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: Colors.greenAccent.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      "${e.key}: ${e.value.toStringAsFixed(0)} Hz",
                      style: GoogleFonts.lato(
                        color: Colors.greenAccent,
                        fontSize: 10,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getColorForValue(double value, String unit) {
    if (unit == "%") {
      if (value >= 80) return Colors.greenAccent;
      if (value >= 60) return Colors.lightGreenAccent;
      if (value >= 40) return Colors.orangeAccent;
      return Colors.redAccent;
    }
    return Colors.greenAccent;
  }

  double _normalizeForProgress(double value, String unit) {
    if (unit == "%") return value / 100;
    if (unit == "Hz") return min(1.0, value / 2000);
    if (unit == "s") return min(1.0, value / 5);
    if (unit == "BPM") return min(1.0, value / 120);
    return 0.5;
  }

  String _formatValue(double value) {
    if (value >= 100) return value.toStringAsFixed(0);
    if (value >= 10) return value.toStringAsFixed(1);
    return value.toStringAsFixed(2);
  }
}
