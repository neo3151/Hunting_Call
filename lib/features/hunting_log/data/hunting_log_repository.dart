import '../domain/hunting_log_entry.dart';

abstract class HuntingLogRepository {
  Future<void> initialize();
  Future<List<HuntingLogEntry>> getLogs();
  Future<void> addLog(HuntingLogEntry entry);
  Future<void> deleteLog(String id);
}
