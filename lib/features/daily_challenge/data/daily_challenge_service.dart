import 'package:intl/intl.dart';
import '../../library/data/reference_database.dart';
import '../../library/domain/reference_call_model.dart';

class DailyChallengeService {
  
  static ReferenceCall getDailyChallenge() {
    // Filter out locked calls (handles Freemium logic automatically)
    final eligibleCalls = ReferenceDatabase.calls.where((c) => !c.isLocked).toList();
    
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
            audioAssetPath: 'assets/audio/duck_mallard_greeting.wav', 
            imageUrl: 'assets/images/waterfowl_hero.png', 
            tolerancePitch: 50, 
            toleranceDuration: 0.2, 
            proTips: 'Keep it simple. The basic quack is the most versatile call.',
            isLocked: false,
          );
       }
    } else {
      final dayOfYear = int.parse(DateFormat("D").format(DateTime.now()));
      final index = dayOfYear % eligibleCalls.length;
      challengeCall = eligibleCalls[index];
    }
    
    // Safety check for image assets
    // If the image path doesn't exist in our known list, fall back to a safe default
    // Note: In a real app we'd check file existence, but here we know 'predator_hero.png' is missing
    if (challengeCall.imageUrl.contains("predator_hero") || challengeCall.imageUrl.contains("big_game_hero")) {
       return challengeCall.copyWith(imageUrl: "assets/images/forest_background.png");
    }
    
    return challengeCall;
  }
}
