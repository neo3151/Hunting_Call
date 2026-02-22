import 'package:hunting_calls_perfection/features/rating/domain/rating_model.dart';

abstract class RatingService {
  Future<RatingResult> rateCall(String userId, String audioPath, String animalType);
}
