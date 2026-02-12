import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import '../../domain/hunting_log_entry.dart';
import '../../data/hunting_log_repository.dart';

final huntingLogRepositoryProvider = Provider<HuntingLogRepository>((ref) {
  return GetIt.I<HuntingLogRepository>();
});

class HuntingLogNotifier extends AsyncNotifier<List<HuntingLogEntry>> {
  @override
  Future<List<HuntingLogEntry>> build() async {
    return _fetchLogs();
  }

  Future<List<HuntingLogEntry>> _fetchLogs() async {
    final repository = ref.read(huntingLogRepositoryProvider);
    return await repository.getLogs();
  }

  Future<void> addLog(HuntingLogEntry entry) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(huntingLogRepositoryProvider);
      await repository.addLog(entry);
      return _fetchLogs();
    });
  }

  Future<void> deleteLog(String id) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(huntingLogRepositoryProvider);
      await repository.deleteLog(id);
      return _fetchLogs();
    });
  }
}

final huntingLogProvider = AsyncNotifierProvider<HuntingLogNotifier, List<HuntingLogEntry>>(() {
  return HuntingLogNotifier();
});
