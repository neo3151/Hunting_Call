import 'package:fpdart/fpdart.dart';
import 'package:hunting_calls_perfection/features/hunting_log/domain/hunting_log_entry.dart';
import 'package:hunting_calls_perfection/features/hunting_log/domain/repositories/hunting_log_repository.dart';
import 'package:hunting_calls_perfection/features/hunting_log/domain/failures/hunting_log_failure.dart';

/// Use case: Get all hunting log entries
/// 
/// Retrieves all log entries from the database, ordered by timestamp (newest first)
class GetAllLogsUseCase {
  final HuntingLogRepository _repository;

  const GetAllLogsUseCase(this._repository);

  /// Execute the use case
  /// 
  /// Returns all log entries or a failure if database isn't initialized
  Future<Either<HuntingLogFailure, List<HuntingLogEntry>>> execute() async {
    try {
      // Ensure database is initialized
      await _repository.initialize();
      
      // Get all logs
      final logs = await _repository.getLogs();
      
      return right(logs);
    } catch (e) {
      // Wrap any exceptions as DatabaseError
      return left(DatabaseError(e.toString()));
    }
  }
}
