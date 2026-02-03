class ReferenceCall {
  final String id;
  final String animalName;
  final double idealPitchHz;
  final double idealDurationSec;
  final String audioAssetPath;
  final double tolerancePitch; // +/- Hz allowed
  final double toleranceDuration; // +/- seconds allowed

  const ReferenceCall({
    required this.id,
    required this.animalName,
    required this.idealPitchHz,
    required this.idealDurationSec,
    required this.audioAssetPath,
    this.tolerancePitch = 50.0,
    this.toleranceDuration = 0.5,
  });
}
