import 'rating_model.dart';

abstract class RatingService {
  Future<RatingResult> rateCall(String userId, String audioPath, String animalType);
}
