/// Sealed class for all analysis failures
sealed class AnalysisFailure {
  const AnalysisFailure();
  
  String get message;
}

/// Audio file not found on disk
class AudioFileNotFound extends AnalysisFailure {
  final String path;
  
  const AudioFileNotFound(this.path);
  
  @override
  String get message => 'Audio file not found: $path';
}

/// Invalid or corrupted audio format
class InvalidAudioFormat extends AnalysisFailure {
  final String details;
  
  const InvalidAudioFormat(this.details);
  
  @override
  String get message => 'Invalid audio format: $details';
}

/// Error during analysis computation (FFT, DSP, etc.)
class AnalysisComputationError extends AnalysisFailure {
  final String details;
  
  const AnalysisComputationError(this.details);
  
  @override
  String get message => 'Analysis failed: $details';
}

/// Reference data not available for the specified animal
class ReferenceDataNotFound extends AnalysisFailure {
  final String animalId;
  
  const ReferenceDataNotFound(this.animalId);
  
  @override
  String get message => 'Reference data not found for: $animalId';
}

/// Audio is too short or too quiet to analyze
class InsufficientAudioData extends AnalysisFailure {
  final String details;
  
  const InsufficientAudioData(this.details);
  
  @override
  String get message => 'Insufficient audio data: $details';
}
