class ReferenceCall {
  final String id;
  final String animalName; // Species name (e.g., Mallard Duck)
  final String callType; // Type of call (e.g., Greeting, Feed)
  final String category; // High-level group (e.g., Waterfowl)
  final String difficulty; // Easy, Intermediate, Pro
  final String description;
  final String proTips;
  final double idealPitchHz;
  final double idealDurationSec;
  final String audioAssetPath;
  final double tolerancePitch; // +/- Hz allowed
  final double toleranceDuration; // +/- seconds allowed
  final String imageUrl; // Custom high-res image
  final String scientificName; // Biological name
  final bool isLocked; // If true, the call is "Coming Soon" or requires unlock

  const ReferenceCall({
    required this.id,
    required this.animalName,
    required this.callType,
    required this.category,
    required this.difficulty,
    this.description = '',
    this.proTips = '',
    required this.idealPitchHz,
    required this.idealDurationSec,
    required this.audioAssetPath,
    this.tolerancePitch = 50.0,
    this.toleranceDuration = 0.5,
    this.imageUrl = '',
    this.scientificName = '',
    this.isLocked = false,
  });

  factory ReferenceCall.fromJson(Map<String, dynamic> json) {
    return ReferenceCall(
      id: json['id'] as String,
      animalName: json['animalName'] as String,
      callType: json['callType'] as String? ?? 'Call',
      category: json['category'] as String? ?? 'General',
      difficulty: json['difficulty'] as String? ?? 'Intermediate',
      description: json['description'] as String? ?? '',
      proTips: json['proTips'] as String? ?? '',
      idealPitchHz: (json['idealPitchHz'] as num).toDouble(),
      idealDurationSec: (json['idealDurationSec'] as num).toDouble(),
      audioAssetPath: json['audioAssetPath'] as String,
      tolerancePitch: (json['tolerancePitch'] as num?)?.toDouble() ?? 50.0,
      toleranceDuration: (json['toleranceDuration'] as num?)?.toDouble() ?? 0.5,
      imageUrl: json['imageUrl'] as String? ?? '',
      scientificName: json['scientificName'] as String? ?? '',
      isLocked: json['isLocked'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'animalName': animalName,
    'callType': callType,
    'category': category,
    'difficulty': difficulty,
    'description': description,
    'proTips': proTips,
    'idealPitchHz': idealPitchHz,
    'idealDurationSec': idealDurationSec,
    'audioAssetPath': audioAssetPath,
    'tolerancePitch': tolerancePitch,
    'toleranceDuration': toleranceDuration,
    'imageUrl': imageUrl,
    'scientificName': scientificName,
    'isLocked': isLocked,
  };
}
