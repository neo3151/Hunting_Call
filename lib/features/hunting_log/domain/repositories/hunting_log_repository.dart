import 'package:outcall/features/hunting_log/domain/hunting_log_entry.dart';

/// Abstract interface for hunting log operations.
/// Lives in the domain layer — implementations go in data/.
abstract class HuntingLogRepository {
  Future<void> initialize();
  Future<List<HuntingLogEntry>> getLogs();
  Future<void> addLog(HuntingLogEntry entry);
  Future<void> deleteLog(String id);
}
