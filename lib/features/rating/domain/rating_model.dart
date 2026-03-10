import 'package:json_annotation/json_annotation.dart';

part 'rating_model.g.dart';

@JsonSerializable(explicitToJson: true)
class RatingResult {
  final double score;
  final String feedback;
  final double pitchHz;
  final Map<String, double> metrics; // e.g. pitch: 80, duration: 90
  final List<double>? userWaveform;
  final List<double>? referenceWaveform;
  final double? latitude;
  final double? longitude;

  /// Feature vectors for long-term progress tracking.
  /// Keys: 'pitchContour', 'formants', 'mfcc39', 'envelope'
  final Map<String, List<double>>? featureVectors;

  /// Closest archetype match label (e.g., "Rutting Mature Bull")
  final String? archetypeLabel;

  RatingResult({
    required this.score,
    required this.feedback,
    required this.pitchHz,
    required this.metrics,
    this.userWaveform,
    this.referenceWaveform,
    this.latitude,
    this.longitude,
    this.featureVectors,
    this.archetypeLabel,
  });

  factory RatingResult.fromJson(Map<String, dynamic> json) => _$RatingResultFromJson(json);
  Map<String, dynamic> toJson() => _$RatingResultToJson(this);
}
