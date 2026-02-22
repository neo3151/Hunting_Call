import 'package:fpdart/fpdart.dart';
import 'package:hunting_calls_perfection/features/hunting_log/domain/repositories/hunting_log_repository.dart';
import 'package:hunting_calls_perfection/features/hunting_log/domain/failures/hunting_log_failure.dart';

/// Use case: Delete a hunting log entry
/// 
/// Deletes a log entry from the database by ID
class DeleteLogUseCase {
  final HuntingLogRepository _repository;

  const DeleteLogUseCase(this._repository);

  /// Execute the use case
  /// 
  /// Returns success (void) or a failure if the operation fails
  Future<Either<HuntingLogFailure, void>> execute(String logId) async {
    try {
      // Ensure database is initialized
      await _repository.initialize();
      
      // Delete the log entry
      await _repository.deleteLog(logId);
      
      return right(null);
    } catch (e) {
      // Wrap any exceptions as DatabaseError
      return left(DatabaseError(e.toString()));
    }
  }
}
