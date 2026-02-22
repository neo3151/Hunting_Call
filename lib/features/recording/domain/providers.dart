import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hunting_calls_perfection/di_providers.dart';
import 'package:hunting_calls_perfection/features/recording/domain/use_cases/start_recording_use_case.dart';
import 'package:hunting_calls_perfection/features/recording/domain/use_cases/stop_recording_use_case.dart';

/// Provider for StartRecordingUseCase
final startRecordingUseCaseProvider = Provider<StartRecordingUseCase>((ref) {
  final recorderService = ref.watch(audioRecorderServiceProvider);
  return StartRecordingUseCase(recorderService);
});

/// Provider for StopRecordingUseCase
final stopRecordingUseCaseProvider = Provider<StopRecordingUseCase>((ref) {
  final recorderService = ref.watch(audioRecorderServiceProvider);
  return StopRecordingUseCase(recorderService);
});

/// Provider for SaveRecordingUseCase
/// Note: This requires a RecordingRepository implementation
/// For now, we'll leave it commented until we create the repository
// final saveRecordingUseCaseProvider = Provider<SaveRecordingUseCase>((ref) {
//   final repository = ref.watch(recordingRepositoryProvider);
//   return SaveRecordingUseCase(repository);
// });
