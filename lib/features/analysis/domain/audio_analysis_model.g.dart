// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'audio_analysis_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AudioAnalysis _$AudioAnalysisFromJson(Map<String, dynamic> json) =>
    AudioAnalysis(
      dominantFrequencyHz: (json['dominantFrequencyHz'] as num).toDouble(),
      averageFrequencyHz: (json['averageFrequencyHz'] as num).toDouble(),
      frequencyPeaks: (json['frequencyPeaks'] as List<dynamic>)
          .map((e) => (e as num).toDouble())
          .toList(),
      pitchStability: (json['pitchStability'] as num).toDouble(),
      pitchTrack: (json['pitchTrack'] as List<dynamic>)
          .map((e) => (e as num).toDouble())
          .toList(),
      averageVolume: (json['averageVolume'] as num).toDouble(),
      peakVolume: (json['peakVolume'] as num).toDouble(),
      volumeConsistency: (json['volumeConsistency'] as num).toDouble(),
      toneClarity: (json['toneClarity'] as num).toDouble(),
      harmonicRichness: (json['harmonicRichness'] as num).toDouble(),
      harmonics: (json['harmonics'] as Map<String, dynamic>).map(
        (k, e) => MapEntry(k, (e as num).toDouble()),
      ),
      brightness: (json['brightness'] as num).toDouble(),
      warmth: (json['warmth'] as num).toDouble(),
      nasality: (json['nasality'] as num).toDouble(),
      spectralCentroid: (json['spectralCentroid'] as List<dynamic>)
          .map((e) => (e as num).toDouble())
          .toList(),
      totalDurationSec: (json['totalDurationSec'] as num).toDouble(),
      activeDurationSec: (json['activeDurationSec'] as num).toDouble(),
      silenceDurationSec: (json['silenceDurationSec'] as num).toDouble(),
      tempo: (json['tempo'] as num).toDouble(),
      pulseTimes: (json['pulseTimes'] as List<dynamic>)
          .map((e) => (e as num).toDouble())
          .toList(),
      rhythmRegularity: (json['rhythmRegularity'] as num).toDouble(),
      isPulsedCall: json['isPulsedCall'] as bool,
      callQualityScore: (json['callQualityScore'] as num).toDouble(),
      noiseLevel: (json['noiseLevel'] as num).toDouble(),
      waveform: (json['waveform'] as List<dynamic>)
          .map((e) => (e as num).toDouble())
          .toList(),
    );

Map<String, dynamic> _$AudioAnalysisToJson(AudioAnalysis instance) =>
    <String, dynamic>{
      'dominantFrequencyHz': instance.dominantFrequencyHz,
      'averageFrequencyHz': instance.averageFrequencyHz,
      'frequencyPeaks': instance.frequencyPeaks,
      'pitchStability': instance.pitchStability,
      'pitchTrack': instance.pitchTrack,
      'averageVolume': instance.averageVolume,
      'peakVolume': instance.peakVolume,
      'volumeConsistency': instance.volumeConsistency,
      'toneClarity': instance.toneClarity,
      'harmonicRichness': instance.harmonicRichness,
      'harmonics': instance.harmonics,
      'brightness': instance.brightness,
      'warmth': instance.warmth,
      'nasality': instance.nasality,
      'spectralCentroid': instance.spectralCentroid,
      'totalDurationSec': instance.totalDurationSec,
      'activeDurationSec': instance.activeDurationSec,
      'silenceDurationSec': instance.silenceDurationSec,
      'tempo': instance.tempo,
      'pulseTimes': instance.pulseTimes,
      'rhythmRegularity': instance.rhythmRegularity,
      'isPulsedCall': instance.isPulsedCall,
      'callQualityScore': instance.callQualityScore,
      'noiseLevel': instance.noiseLevel,
      'waveform': instance.waveform,
    };
