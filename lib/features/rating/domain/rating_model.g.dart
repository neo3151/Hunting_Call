// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'rating_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RatingResult _$RatingResultFromJson(Map<String, dynamic> json) => RatingResult(
      score: (json['score'] as num).toDouble(),
      feedback: json['feedback'] as String,
      pitchHz: (json['pitchHz'] as num).toDouble(),
      metrics: (json['metrics'] as Map<String, dynamic>).map(
        (k, e) => MapEntry(k, (e as num).toDouble()),
      ),
      userWaveform: (json['userWaveform'] as List<dynamic>?)
          ?.map((e) => (e as num).toDouble())
          .toList(),
      referenceWaveform: (json['referenceWaveform'] as List<dynamic>?)
          ?.map((e) => (e as num).toDouble())
          .toList(),
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$RatingResultToJson(RatingResult instance) =>
    <String, dynamic>{
      'score': instance.score,
      'feedback': instance.feedback,
      'pitchHz': instance.pitchHz,
      'metrics': instance.metrics,
      'userWaveform': instance.userWaveform,
      'referenceWaveform': instance.referenceWaveform,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
    };
