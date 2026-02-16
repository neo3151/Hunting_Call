import '../domain/daily_challenge_repository.dart';
import '../../library/domain/reference_call_model.dart';
import '../../library/data/reference_database.dart';
import 'package:intl/intl.dart';

/// Concrete implementation of [DailyChallengeRepository].
/// Selects a daily challenge based on the day of the year from the
/// pool of free (unlocked) reference calls.
///
/// Class name kept as DailyChallengeService for backwards compatibility —
/// existing code calls DailyChallengeService.getDailyChallenge() statically.
class DailyChallengeService implements DailyChallengeRepository {
  @override
  ReferenceCall getDailyChallenge() {
    return _getDailyChallenge();
  }

  /// Static accessor for backwards compatibility.
  static ReferenceCall getDailyChallengeStatic() {
    return _getDailyChallenge();
  }

  static ReferenceCall _getDailyChallenge() {
    // Filter out locked calls (ensure challenges are from Free Tier so everyone can play)
    // We pass 'false' for isPremium to force the check against the Free Starter Pack.
    final eligibleCalls = ReferenceDatabase.calls.where((c) => !ReferenceDatabase.isLocked(c.id, false)).toList();
    
    ReferenceCall challengeCall;
    if (eligibleCalls.isEmpty) {
      // Fallback
       if (ReferenceDatabase.calls.isNotEmpty) {
         challengeCall = ReferenceDatabase.calls.first;
       } else {
          // Hard fallback
          challengeCall = const ReferenceCall(
            id: 'duck_mallard', 
            animalName: 'Mallard Duck', 
            callType: 'Basic Quack', 
            category: 'Waterfowl',
            scientificName: 'Anas platyrhynchos', 
            description: 'The mallard is a dabbling duck that breeds throughout the temperate and subtropical Americas, Eurasia, and North Africa.', 
            difficulty: 'Easy', 
            idealPitchHz: 400, 
            idealDurationSec: 1.0, 
            audioAssetPath: 'assets/audio/duck_mallard_greeting.mp3', 
            imageUrl: 'assets/images/waterfowl_hero.png', 
            tolerancePitch: 50, 
            toleranceDuration: 0.2, 
            proTips: 'Keep it simple. The basic quack is the most versatile call.',
            isLocked: false,
          );
       }
    } else {
      final dayOfYear = int.parse(DateFormat('D').format(DateTime.now()));
      final index = dayOfYear % eligibleCalls.length;
      challengeCall = eligibleCalls[index];
    }
    
    // Safety check for image assets
    if (challengeCall.imageUrl.contains('predator_hero') || challengeCall.imageUrl.contains('big_game_hero')) {
       return challengeCall.copyWith(imageUrl: 'assets/images/forest_background.png');
    }
    
    return challengeCall;
  }
}
