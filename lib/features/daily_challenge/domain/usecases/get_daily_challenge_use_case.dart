import 'package:fpdart/fpdart.dart';
import 'package:intl/intl.dart';
import 'package:outcall/features/library/domain/reference_call_model.dart';
import 'package:outcall/features/library/domain/use_cases/get_all_calls_use_case.dart';
import 'package:outcall/features/library/domain/use_cases/check_call_lock_status_use_case.dart';
import 'package:outcall/features/daily_challenge/domain/failures/daily_challenge_failure.dart';
import 'package:outcall/features/daily_challenge/domain/daily_challenge_repository.dart';

/// Use case: Get today's daily challenge call.
/// 
/// First attempts to fetch from Cloud/Cache via [DailyChallengeRepository].
/// If that fails or returns null, falls back to mathematical selection.
class GetDailyChallengeUseCase {
  final GetAllCallsUseCase _getAllCallsUseCase;
  final CheckCallLockStatusUseCase _checkLockStatusUseCase;
  final DailyChallengeRepository _repository;

  const GetDailyChallengeUseCase(
    this._getAllCallsUseCase,
    this._checkLockStatusUseCase,
    this._repository,
  );

  /// Execute the use case asynchronously
  /// 
  /// Returns today's challenge call or a failure if none available
  Future<Either<DailyChallengeFailure, ReferenceCall>> execute({DateTime? now}) async {
    try {
      // 1. Check if Cloud/Cache has a specific daily challenge for us
      final cloudChallengeId = await _repository.getDailyChallengeId();
      
      // Get all available calls
      final allCallsResult = _getAllCallsUseCase.execute();
      
      return allCallsResult.fold(
        (failure) => right(_getDefaultChallenge()),
        (allCalls) {
          // If we got a cloud ID, try to find it
          if (cloudChallengeId != null) {
            try {
               final matchedCall = allCalls.firstWhere((call) => call.id == cloudChallengeId);
               return right(_fixImageAsset(matchedCall));
            } catch (e) {
               // Cloud ID wasn't found in our library, fallback gracefully
            }
          }

          // Fallback Strategy: Filter to free calls based on Day of Year
          final freeCalls = allCalls.where((call) {
            final lockResult = _checkLockStatusUseCase.execute(
              callId: call.id,
              isUserPremium: false, // Force check against free tier
            );
            return lockResult.getOrElse((l) => false) == false; // Not locked = free
          }).toList();

          if (freeCalls.isEmpty) {
            // Fallback: if no free calls, use first call from all calls
            if (allCalls.isNotEmpty) {
              return right(_fixImageAsset(allCalls.first));
            }
            // Hard fallback: return default mallard call
            return right(_getDefaultChallenge());
          }

          // Select challenge based on day of year
          try {
            final currentDate = now ?? DateTime.now();
            final dayOfYear = int.parse(DateFormat('D').format(currentDate));
            final index = dayOfYear % freeCalls.length;
            final selectedCall = freeCalls[index];
            
            return right(_fixImageAsset(selectedCall));
          } catch (e) {
            return left(InvalidDateFormat(e.toString()));
          }
        },
      );
    } catch (e) {
      return left(InvalidDateFormat(e.toString()));
    }
  }

  /// Fix image asset path for certain hero images
  ReferenceCall _fixImageAsset(ReferenceCall call) {
    if (call.imageUrl.contains('predator_hero') || 
        call.imageUrl.contains('big_game_hero')) {
      return call.copyWith(imageUrl: 'assets/images/forest_background.png');
    }
    return call;
  }

  /// Default fallback challenge when no calls available
  ReferenceCall _getDefaultChallenge() {
    return const ReferenceCall(
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
}
