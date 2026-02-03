import 'package:json_annotation/json_annotation.dart';

part 'audio_analysis_model.g.dart';

/// Comprehensive audio analysis results
@JsonSerializable()
class AudioAnalysis {
  /// Pitch Analysis
  final double dominantFrequencyHz;
  final double averageFrequencyHz;
  final List<double> frequencyPeaks; // Top 5 frequency peaks
  final double pitchStability; // 0-100, how stable the pitch is
  
  /// Volume Analysis
  final double averageVolume; // RMS amplitude 0-1
  final double peakVolume; // Maximum amplitude
  final double volumeConsistency; // 0-100, how consistent volume is
  
  /// Tone Analysis
  final double toneClarity; // 0-100, how clear vs noisy
  final double harmonicRichness; // 0-100, presence of harmonics
  final Map<String, double> harmonics; // Harmonic frequencies detected
  
  /// Timbre Analysis
  final double brightness; // 0-100, high frequency content
  final double warmth; // 0-100, low frequency content
  final double nasality; // 0-100, presence of nasal frequencies
  final List<double> spectralCentroid; // Brightness over time
  
  /// Duration Analysis
  final double totalDurationSec;
  final double activeDurationSec; // Time above noise threshold
  final double silenceDurationSec; // Time below noise threshold
  
  /// Rhythm Analysis
  final double tempo; // Calls per minute (if pulsed)
  final List<double> pulseTimes; // Timestamps of detected pulses
  final double rhythmRegularity; // 0-100, how regular the rhythm is
  final bool isPulsedCall; // Whether call has rhythmic pulses
  
  /// Overall Metrics
  final double callQualityScore; // 0-100, overall technical quality
  final double noiseLevel; // 0-100, background noise estimate
  
  AudioAnalysis({
    required this.dominantFrequencyHz,
    required this.averageFrequencyHz,
    required this.frequencyPeaks,
    required this.pitchStability,
    required this.averageVolume,
    required this.peakVolume,
    required this.volumeConsistency,
    required this.toneClarity,
    required this.harmonicRichness,
    required this.harmonics,
    required this.brightness,
    required this.warmth,
    required this.nasality,
    required this.spectralCentroid,
    required this.totalDurationSec,
    required this.activeDurationSec,
    required this.silenceDurationSec,
    required this.tempo,
    required this.pulseTimes,
    required this.rhythmRegularity,
    required this.isPulsedCall,
    required this.callQualityScore,
    required this.noiseLevel,
  });

  factory AudioAnalysis.fromJson(Map<String, dynamic> json) => _$AudioAnalysisFromJson(json);
  Map<String, dynamic> toJson() => _$AudioAnalysisToJson(this);
  
  /// Create a simplified analysis with defaults (for backward compatibility)
  factory AudioAnalysis.simple({
    required double frequencyHz,
    required double durationSec,
    double volume = 0.5,
  }) {
    return AudioAnalysis(
      dominantFrequencyHz: frequencyHz,
      averageFrequencyHz: frequencyHz,
      frequencyPeaks: [frequencyHz],
      pitchStability: 50.0,
      averageVolume: volume,
      peakVolume: volume * 1.5,
      volumeConsistency: 50.0,
      toneClarity: 50.0,
      harmonicRichness: 50.0,
      harmonics: {},
      brightness: 50.0,
      warmth: 50.0,
      nasality: 50.0,
      spectralCentroid: [],
      totalDurationSec: durationSec,
      activeDurationSec: durationSec * 0.9,
      silenceDurationSec: durationSec * 0.1,
      tempo: 0.0,
      pulseTimes: [],
      rhythmRegularity: 0.0,
      isPulsedCall: false,
      callQualityScore: 50.0,
      noiseLevel: 20.0,
    );
  }
}

/// Analysis summary for display
class AnalysisSummary {
  final String category;
  final String metric;
  final double value;
  final String unit;
  final String description;
  final AnalysisRating rating;
  
  AnalysisSummary({
    required this.category,
    required this.metric,
    required this.value,
    required this.unit,
    required this.description,
    required this.rating,
  });
}

enum AnalysisRating {
  excellent,
  good,
  fair,
  poor,
}
