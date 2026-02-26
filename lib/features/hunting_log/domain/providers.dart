import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:outcall/di_providers.dart';
import 'package:outcall/features/hunting_log/domain/usecases/get_all_logs_use_case.dart';
import 'package:outcall/features/hunting_log/domain/usecases/add_log_use_case.dart';
import 'package:outcall/features/hunting_log/domain/usecases/delete_log_use_case.dart';

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
