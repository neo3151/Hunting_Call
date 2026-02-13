/// Sealed class for all recording failures
sealed class RecordingFailure {
  const RecordingFailure();
  
  String get message;
}

/// Microphone permission was denied
class PermissionDenied extends RecordingFailure {
  const PermissionDenied();
  
  @override
  String get message => 'Microphone permission denied';
}

/// Attempted to start recording while already recording
class RecordingInProgress extends RecordingFailure {
  const RecordingInProgress();
  
  @override
  String get message => 'Recording already in progress';
}

/// Recording duration was too short
class RecordingTooShort extends RecordingFailure {
  final Duration minDuration;
  final Duration actualDuration;
  
  const RecordingTooShort(this.minDuration, this.actualDuration);
  
  @override
  String get message => 
    'Recording too short. Minimum: ${minDuration.inSeconds}s, got: ${actualDuration.inSeconds}s';
}

/// Error from the recording service (hardware/OS level)
class RecordingServiceError extends RecordingFailure {
  final String details;
  
  const RecordingServiceError(this.details);
  
  @override
  String get message => 'Recording error: $details';
}

/// File system error (can't write/read audio file)
class FileSystemError extends RecordingFailure {
  final String details;
  
  const FileSystemError(this.details);
  
  @override
  String get message => 'File system error: $details';
}

/// Recording not found in storage
class RecordingNotFound extends RecordingFailure {
  final String id;
  
  const RecordingNotFound(this.id);
  
  @override
  String get message => 'Recording not found: $id';
}
