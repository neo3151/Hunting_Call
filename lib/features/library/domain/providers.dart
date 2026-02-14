import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'use_cases/get_all_calls_use_case.dart';
import 'use_cases/get_call_by_id_use_case.dart';
import 'use_cases/filter_calls_use_case.dart';
import 'use_cases/check_call_lock_status_use_case.dart';

/// Provider for GetAllCallsUseCase
final getAllCallsUseCaseProvider = Provider<GetAllCallsUseCase>((ref) {
  return const GetAllCallsUseCase();
});

/// Provider for GetCallByIdUseCase
final getCallByIdUseCaseProvider = Provider<GetCallByIdUseCase>((ref) {
  return const GetCallByIdUseCase();
});

/// Provider for FilterCallsUseCase
final filterCallsUseCaseProvider = Provider<FilterCallsUseCase>((ref) {
  return const FilterCallsUseCase();
});

/// Provider for CheckCallLockStatusUseCase
final checkCallLockStatusUseCaseProvider = Provider<CheckCallLockStatusUseCase>((ref) {
  return const CheckCallLockStatusUseCase();
});
