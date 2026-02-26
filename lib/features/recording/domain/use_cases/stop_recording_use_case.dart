import 'dart:io';
import 'package:fpdart/fpdart.dart';
import 'package:outcall/features/recording/domain/audio_recorder_service.dart';
import 'package:outcall/features/recording/domain/failures/recording_failure.dart';

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
      
      final file = File(audioPath);
      final stat = await file.stat();
      // Basic check: if file is too small, it's likely an empty or failed recording
      if (stat.size < 1024) { // Less than 1KB
        return left(const RecordingServiceError('Recording too short or empty'));
      }
      
      return right(audioPath);
    } catch (e) {
      return left(RecordingServiceError(e.toString()));
    }
  }
}
