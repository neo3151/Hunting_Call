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
        description: 'Fallback', 
        difficulty: 'Easy', 
        idealPitchHz: 400, 
        idealDurationSec: 1.0, 
        audioAssetPath: 'assets/audio/duck_mallard.wav', 
        imageUrl: 'assets/images/duck.jpg', 
        tolerancePitch: 50, 
        toleranceDuration: 0.2, 
        proTips: ''
      );
    }
    
    final dayOfYear = int.parse(DateFormat("D").format(DateTime.now()));
    final index = dayOfYear % allCalls.length;
    return allCalls[index];
  }
}
