import 'package:fpdart/fpdart.dart';
import 'package:outcall/features/profile/domain/failures/profile_failure.dart';
import 'package:outcall/features/profile/domain/entities/user_profile.dart';
import 'package:outcall/features/profile/domain/achievement_service.dart';

/// Use case for calculating new achievements earned by a user
/// 
/// Extracted from ProfileNotifier - business logic should be in domain layer
class CalculateNewAchievementsUseCase {
  /// Determine which achievements are newly earned
  /// 
  /// Returns list of new achievement IDs that weren't previously earned
  Either<ProfileFailure, List<String>> execute(
    UserProfile profile,
    List<String> currentAchievementIds,
  ) {
    try {
      // AchievementService has static methods
      final newIds = AchievementService.getNewAchievementIds(
        profile,
        currentAchievementIds,
      );
      
      return Right(newIds);
    } catch (e) {
      return Left(AchievementCalculationFailed(e.toString()));
    }
  }
}
