import 'package:equatable/equatable.dart';

/// Represents an aggregated "archetype" derived from multiple expert audio clips
/// of the same animal call. Rather than matching user performance against a single
/// clip via 1:1 similarity, the analyzer compares it against these dynamic bounds.
class AnimalArchetype extends Equatable {
  final String callId; // Links to ReferenceCall.id
  
  // Pitch
  final double averagePitchHz;
  final double pitchTolerance; // +/- allowed deviation
  
  // Duration
  final double averageDurationSec;
  final double durationTolerance; // +/- allowed deviation
  
  // Tone & Harmonics
  final Map<String, double> harmonicsProfile; // e.g. {'H2': 1.5, 'H3': 0.8}
  final List<double> mfccProfile; // Average MFCC vector across expert clips
  
  // Rhythm
  final bool isPulsed;
  final List<double> cadenceBreaks; // Average timings of distinct pulses/notes
  final List<double> averageWaveform; // Representative DTW-aligned envelope

  const AnimalArchetype({
    required this.callId,
    required this.averagePitchHz,
    required this.pitchTolerance,
    required this.averageDurationSec,
    required this.durationTolerance,
    this.harmonicsProfile = const {},
    this.mfccProfile = const [],
    this.isPulsed = false,
    this.cadenceBreaks = const [],
    this.averageWaveform = const [],
  });

  @override
  List<Object?> get props => [
        callId,
        averagePitchHz,
        pitchTolerance,
        averageDurationSec,
        durationTolerance,
        harmonicsProfile,
        mfccProfile,
        isPulsed,
        cadenceBreaks,
        averageWaveform,
      ];

  factory AnimalArchetype.fromJson(Map<String, dynamic> json) {
    return AnimalArchetype(
      callId: json['callId'] as String,
      averagePitchHz: (json['averagePitchHz'] as num).toDouble(),
      pitchTolerance: (json['pitchTolerance'] as num).toDouble(),
      averageDurationSec: (json['averageDurationSec'] as num).toDouble(),
      durationTolerance: (json['durationTolerance'] as num).toDouble(),
      harmonicsProfile: (json['harmonicsProfile'] as Map<String, dynamic>?)
              ?.map((k, v) => MapEntry(k, (v as num).toDouble())) ??
          const {},
      mfccProfile: (json['mfccProfile'] as List<dynamic>?)
              ?.map((e) => (e as num).toDouble())
              .toList() ??
          const [],
      isPulsed: json['isPulsed'] as bool? ?? false,
      cadenceBreaks: (json['cadenceBreaks'] as List<dynamic>?)
              ?.map((e) => (e as num).toDouble())
              .toList() ??
          const [],
      averageWaveform: (json['averageWaveform'] as List<dynamic>?)
              ?.map((e) => (e as num).toDouble())
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() => {
        'callId': callId,
        'averagePitchHz': averagePitchHz,
        'pitchTolerance': pitchTolerance,
        'averageDurationSec': averageDurationSec,
        'durationTolerance': durationTolerance,
        'harmonicsProfile': harmonicsProfile,
        'mfccProfile': mfccProfile,
        'isPulsed': isPulsed,
        'cadenceBreaks': cadenceBreaks,
        'averageWaveform': averageWaveform,
      };
}
