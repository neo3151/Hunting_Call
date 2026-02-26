import 'package:fpdart/fpdart.dart';
import 'package:outcall/features/recording/domain/audio_recorder_service.dart';
import 'package:outcall/features/recording/domain/failures/recording_failure.dart';

/// Use case for starting a recording session with countdown
class StartRecordingUseCase {
  final AudioRecorderService _recorderService;
  
  const StartRecordingUseCase(this._recorderService);
  
  /// Execute the use case with countdown
  /// 
  /// [outputPath] - Where to save the recording
  /// [countdownSeconds] - How long to count down before starting (default: 3)
  /// [onCountdownTick] - Callback for countdown updates (0 means countdown complete)
  Future<Either<RecordingFailure, String>> execute({
    required String outputPath,
    int countdownSeconds = 3,
    required void Function(int) onCountdownTick,
  }) async {
    // Countdown
    for (int i = countdownSeconds; i > 0; i--) {
      onCountdownTick(i);
      await Future.delayed(const Duration(seconds: 1));
    }
    onCountdownTick(0); // Countdown complete
    
    // Start recording
    try {
      final success = await _recorderService.startRecorder(outputPath);
      
      if (!success) {
        final error = _recorderService.lastError ?? 'Unknown error';
        return left(RecordingServiceError(error));
      }
      
      return right(outputPath);
    } catch (e) {
      return left(RecordingServiceError(e.toString()));
    }
  }
}
