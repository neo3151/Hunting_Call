import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hunting_calls_perfection/di_providers.dart';
import 'usecases/get_all_logs_use_case.dart';
import 'usecases/add_log_use_case.dart';
import 'usecases/delete_log_use_case.dart';

/// Provider for GetAllLogsUseCase
final getAllLogsUseCaseProvider = Provider<GetAllLogsUseCase>((ref) {
  final repository = ref.watch(huntingLogRepositoryProvider);
  return GetAllLogsUseCase(repository);
});

/// Provider for AddLogUseCase
final addLogUseCaseProvider = Provider<AddLogUseCase>((ref) {
  final repository = ref.watch(huntingLogRepositoryProvider);
  return AddLogUseCase(repository);
});

/// Provider for DeleteLogUseCase
final deleteLogUseCaseProvider = Provider<DeleteLogUseCase>((ref) {
  final repository = ref.watch(huntingLogRepositoryProvider);
  return DeleteLogUseCase(repository);
});
