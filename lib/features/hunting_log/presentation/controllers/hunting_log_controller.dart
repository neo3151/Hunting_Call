import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/hunting_log_entry.dart';
import '../../domain/providers.dart';

class HuntingLogNotifier extends AsyncNotifier<List<HuntingLogEntry>> {
  @override
  Future<List<HuntingLogEntry>> build() async {
    return _fetchLogs();
  }

  Future<List<HuntingLogEntry>> _fetchLogs() async {
    final getAllLogsUseCase = ref.read(getAllLogsUseCaseProvider);
    final result = await getAllLogsUseCase.execute();
    
    return result.fold(
      (failure) {
        // Log error and return empty list to avoid breaking UI
        return <HuntingLogEntry>[];
      },
      (logs) => logs,
    );
  }

  Future<void> addLog(HuntingLogEntry entry) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final addLogUseCase = ref.read(addLogUseCaseProvider);
      final result = await addLogUseCase.execute(entry);
      
      // Handle result
      return result.fold(
        (failure) => throw Exception(failure.message),
        (_) => _fetchLogs(),
      );
    });
  }

  Future<void> deleteLog(String id) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final deleteLogUseCase = ref.read(deleteLogUseCaseProvider);
      final result = await deleteLogUseCase.execute(id);
      
      // Handle result
      return result.fold(
        (failure) => throw Exception(failure.message),
        (_) => _fetchLogs(),
      );
    });
  }
}

final huntingLogProvider = AsyncNotifierProvider<HuntingLogNotifier, List<HuntingLogEntry>>(() {
  return HuntingLogNotifier();
});
