import 'package:intl/intl.dart';
import '../../library/data/reference_database.dart';
import '../../library/domain/reference_call_model.dart';

class DailyChallengeService {
  
  static ReferenceCall getDailyChallenge() {
    final allCalls = ReferenceDatabase.calls;
    if (allCalls.isEmpty) {
      // Fallback
      return ReferenceCall(
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
        proTips: 'Keep it simple. The basic quack is the most versatile call.'
      );
    }
    
    final dayOfYear = int.parse(DateFormat("D").format(DateTime.now()));
    final index = dayOfYear % allCalls.length;
    return allCalls[index];
  }
}
