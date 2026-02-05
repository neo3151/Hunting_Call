import 'package:json_annotation/json_annotation.dart';

part 'rating_model.g.dart';

@JsonSerializable()
class RatingResult {
  final double score;
  final String feedback;
  final double pitchHz;
  final Map<String, double> metrics; // e.g. pitch: 80, duration: 90
  final List<double>? userWaveform;
  final List<double>? referenceWaveform;
  final double? latitude;
  final double? longitude;

  RatingResult({
    required this.score,
    required this.feedback,
    required this.pitchHz,
    required this.metrics,
    this.userWaveform,
    this.referenceWaveform,
    this.latitude,
    this.longitude,
  });

  factory RatingResult.fromJson(Map<String, dynamic> json) => _$RatingResultFromJson(json);
  Map<String, dynamic> toJson() => _$RatingResultToJson(this);
}
