import 'package:fpdart/fpdart.dart';
import '../hunting_log_entry.dart';
import '../repositories/hunting_log_repository.dart';
import '../failures/hunting_log_failure.dart';

/// Use case: Add a new hunting log entry
/// 
/// Adds a log entry to the database
class AddLogUseCase {
  final HuntingLogRepository _repository;

  const AddLogUseCase(this._repository);

  /// Execute the use case
  /// 
  /// Returns success (void) or a failure if the operation fails
  Future<Either<HuntingLogFailure, void>> execute(HuntingLogEntry entry) async {
    try {
      // Ensure database is initialized
      await _repository.initialize();
      
      // Add the log entry
      await _repository.addLog(entry);
      
      return right(null);
    } catch (e) {
      // Wrap any exceptions as DatabaseError
      return left(DatabaseError(e.toString()));
    }
  }
}
