/// Sealed class for all hunting log failures
sealed class HuntingLogFailure {
  const HuntingLogFailure();
  
  String get message;
}

/// Database hasn't been initialized
class DatabaseNotInitialized extends HuntingLogFailure {
  const DatabaseNotInitialized();
  
  @override
  String get message => 'Database not initialized. Please try again.';
}

/// Requested log entry doesn't exist
class LogNotFound extends HuntingLogFailure {
  final String logId;
  
  const LogNotFound(this.logId);
  
  @override
  String get message => 'Log entry not found: $logId';
}

/// Database operation failed
class DatabaseError extends HuntingLogFailure {
  final String details;
  
  const DatabaseError(this.details);
  
  @override
  String get message => 'Database error: $details';
}
