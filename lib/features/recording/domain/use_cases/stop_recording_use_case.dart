import 'package:fpdart/fpdart.dart';
import '../audio_recorder_service.dart';
import '../failures/recording_failure.dart';

/// Use case for stopping a recording session
class StopRecordingUseCase {
  final AudioRecorderService _recorderService;
  
  const StopRecordingUseCase(this._recorderService);
  
  /// Stop recording and return the audio file path
  /// 
  /// [minDuration] - Minimum acceptable recording duration (optional validation)
  Future<Either<RecordingFailure, String>> execute({
    Duration minDuration = const Duration(seconds: 1),
  }) async {
    try {
      final audioPath = await _recorderService.stopRecorder();
      
      if (audioPath == null || audioPath.isEmpty) {
        return left(const RecordingServiceError('No audio path returned'));
      }
      
      // TODO: Could validate duration here if we have access to file metadata
      // For now, just return the path
      
      return right(audioPath);
    } catch (e) {
      return left(RecordingServiceError(e.toString()));
    }
  }
}
