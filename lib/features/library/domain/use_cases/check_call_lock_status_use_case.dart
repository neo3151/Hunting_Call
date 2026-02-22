import 'package:fpdart/fpdart.dart';
import 'package:hunting_calls_perfection/features/library/data/reference_database.dart';
import 'package:hunting_calls_perfection/features/library/domain/failures/library_failure.dart';

/// Use case for checking if a call is locked based on user premium status
class CheckCallLockStatusUseCase {
  const CheckCallLockStatusUseCase();
  
  /// Execute the use case
  /// 
  /// [callId] - The unique identifier of the call to check
  /// [isUserPremium] - Whether the current user has premium access
  /// 
  /// Returns true if the call is locked, false if unlocked
  Either<LibraryFailure, bool> execute({
    required String callId,
    required bool isUserPremium,
  }) {
    try {
      final isLocked = ReferenceDatabase.isLocked(callId, isUserPremium);
      return right(isLocked);
    } catch (e) {
      return left(JsonLoadError(e.toString()));
    }
  }
}
