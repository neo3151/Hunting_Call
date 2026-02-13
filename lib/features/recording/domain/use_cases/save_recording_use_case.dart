import 'package:fpdart/fpdart.dart';
import '../entities/recording.dart';
import '../repositories/recording_repository.dart';
import '../failures/recording_failure.dart';

/// Parameters for saving a recording
class SaveRecordingParams {
  final String userId;
  final String animalId;
  final String audioPath;
  final Duration duration;
  
  const SaveRecordingParams({
    required this.userId,
    required this.animalId,
    required this.audioPath,
    required this.duration,
  });
}

/// Use case for saving a recording to persistent storage
class SaveRecordingUseCase {
  final RecordingRepository _repository;
  
  const SaveRecordingUseCase(this._repository);
  
  /// Save a recording with validation
  Future<Either<RecordingFailure, Recording>> execute(SaveRecordingParams params) async {
    // Validation: minimum duration
    if (params.duration.inSeconds < 1) {
      return left(RecordingTooShort(
        const Duration(seconds: 1),
        params.duration,
      ));
    }
    
    // Create domain entity
    final recording = Recording(
      id: DateTime.now().millisecondsSinceEpoch.toString(), // Temporary ID
      userId: params.userId,
      animalId: params.animalId,
      audioPath: params.audioPath,
      recordedAt: DateTime.now(),
      duration: params.duration,
      score: null, // Will be calculated later by analysis feature
    );
    
    // Save via repository
    return await _repository.save(recording);
  }
}
