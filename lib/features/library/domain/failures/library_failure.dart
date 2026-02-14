/// Sealed class for all library failures
sealed class LibraryFailure {
  const LibraryFailure();
  
  String get message;
}

/// Library database hasn't been initialized yet
class LibraryNotInitialized extends LibraryFailure {
  const LibraryNotInitialized();
  
  @override
  String get message => 'Library not initialized. Please wait while we load the calls.';
}

/// Requested call ID doesn't exist in the database
class CallNotFound extends LibraryFailure {
  final String callId;
  
  const CallNotFound(this.callId);
  
  @override
  String get message => 'Call not found: $callId';
}

/// Failed to load the reference calls JSON file
class JsonLoadError extends LibraryFailure {
  final String details;
  
  const JsonLoadError(this.details);
  
  @override
  String get message => 'Failed to load call library: $details';
}
