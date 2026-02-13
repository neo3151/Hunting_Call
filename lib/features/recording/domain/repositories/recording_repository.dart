import 'package:fpdart/fpdart.dart';
import '../entities/recording.dart';
import '../failures/recording_failure.dart';

/// Repository interface for recording persistence
/// 
/// Defines the contract for saving and retrieving recordings.
/// Implementations should handle data persistence (Firestore, SQLite, etc.)
abstract class RecordingRepository {
  /// Save a recording to persistent storage
  Future<Either<RecordingFailure, Recording>> save(Recording recording);
  
  /// Get all recordings for a specific user
  Future<Either<RecordingFailure, List<Recording>>> getByUserId(String userId);
  
  /// Get a single recording by its ID
  Future<Either<RecordingFailure, Recording>> getById(String id);
  
  /// Delete a recording from storage
  Future<Either<RecordingFailure, Unit>> delete(String id);
  
  /// Update an existing recording (e.g., after scoring)
  Future<Either<RecordingFailure, Recording>> update(Recording recording);
}
