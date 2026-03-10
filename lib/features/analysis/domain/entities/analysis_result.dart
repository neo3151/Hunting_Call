/// Score component for pitch accuracy
class PitchScore {
  final double score;
  final double actualHz;
  final double idealHz;
  final double deviation;
  
  const PitchScore({
    required this.score,
    required this.actualHz,
    required this.idealHz,
    required this.deviation,
  });
  
  @override
  String toString() => 'PitchScore(score: $score, actual: ${actualHz}Hz, ideal: ${idealHz}Hz)';
}

/// Score component for duration accuracy
class DurationScore {
  final double score;
  final double actualSec;
  final double idealSec;
  final double deviation;
  
  const DurationScore({
    required this.score,
    required this.actualSec,
    required this.idealSec,
    required this.deviation,
  });
  
  @override
  String toString() => 'DurationScore(score: $score, actual: ${actualSec}s, ideal: ${idealSec}s)';
}

/// Score component for volume quality
class VolumeScore {
  final double score;
  final double volumeDb;
  final double consistency;
  
  const VolumeScore({
    required this.score,
    required this.volumeDb,
    required this.consistency,
  });
  
  @override
  String toString() => 'VolumeScore(score: $score, volume: ${volumeDb}dB)';
}

/// Score component for tone quality
class ToneScore {
  final double score;
  final double brightness;
  final double warmth;
  final double nasality;
  
  const ToneScore({
    required this.score,
    required this.brightness,
    required this.warmth,
    required this.nasality,
  });
  
  @override
  String toString() => 'ToneScore(score: $score)';
}

/// Score component for rhythm quality
class RhythmScore {
  final double score;
  final double stability;
  final double regularity;
  final double tempo;
  
  const RhythmScore({
    required this.score,
    required this.stability,
    required this.regularity,
    required this.tempo,
  });
  
  @override
  String toString() => 'RhythmScore(score: $score)';
}

// ─── New 7-Dimension Score Components ─────────────────────────────

/// Score component for pitch contour shape matching
class PitchContourScore {
  final double score;
  final double contourSimilarity; // DTW distance on pitch sequences
  final double flatnessDeviation; // how much the contour deviates from expected shape

  const PitchContourScore({
    required this.score,
    this.contourSimilarity = 0,
    this.flatnessDeviation = 0,
  });
}

/// Score component for amplitude envelope (ADSR) match
class EnvelopeScore {
  final double score;
  final double attackMatch; // 0-100 how close attack is to reference
  final double sustainMatch; // 0-100 sustain level similarity
  final double decayMatch; // 0-100 decay rate similarity

  const EnvelopeScore({
    required this.score,
    this.attackMatch = 0,
    this.sustainMatch = 0,
    this.decayMatch = 0,
  });
}

/// Score component for formant analysis (F1/F2/F3 resonances)
class FormantScore {
  final double score;
  final List<double> userFormants; // [F1, F2, F3]
  final List<double> refFormants;  // [F1, F2, F3]

  const FormantScore({
    required this.score,
    this.userFormants = const [],
    this.refFormants = const [],
  });
}

/// Score component for noise robustness (spectral flux)
class NoiseScore {
  final double score;
  final double spectralFlux; // raw flux value

  const NoiseScore({
    required this.score,
    this.spectralFlux = 0,
  });
}

/// Result of analyzing a user's call recording
class AnalysisResult {
  final String recordingId;
  final String userId;
  final String animalId;
  final double overallScore;
  final PitchScore pitchScore;
  final VolumeScore volumeScore;
  final DurationScore durationScore;
  final ToneScore toneScore;
  final RhythmScore rhythmScore;
  // New 7-dimension scores
  final PitchContourScore pitchContourScore;
  final EnvelopeScore envelopeScore;
  final FormantScore formantScore;
  final NoiseScore noiseScore;
  final double? fingerprintMatchPercent; // From backend, null if offline
  final DateTime analyzedAt;
  
  const AnalysisResult({
    required this.recordingId,
    required this.userId,
    required this.animalId,
    required this.overallScore,
    required this.pitchScore,
    required this.volumeScore,
    required this.durationScore,
    required this.toneScore,
    required this.rhythmScore,
    this.pitchContourScore = const PitchContourScore(score: 0),
    this.envelopeScore = const EnvelopeScore(score: 0),
    this.formantScore = const FormantScore(score: 0),
    this.noiseScore = const NoiseScore(score: 0),
    this.fingerprintMatchPercent,
    required this.analyzedAt,
  });
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AnalysisResult && other.recordingId == recordingId;
  }
  
  @override
  int get hashCode => recordingId.hashCode;
  
  @override
  String toString() {
    return 'AnalysisResult(id: $recordingId, score: $overallScore, animal: $animalId)';
  }
}
