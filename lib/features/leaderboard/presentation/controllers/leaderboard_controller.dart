import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:outcall/features/leaderboard/domain/leaderboard_entry.dart';
import 'package:outcall/features/leaderboard/domain/repositories/leaderboard_service.dart';
import 'package:outcall/features/profile/domain/entities/user_profile.dart';
import 'package:outcall/di_providers.dart';

final leaderboardScoresProvider = StreamProvider.family<List<LeaderboardEntry>, String>((ref, animalId) {
  final service = ref.watch(leaderboardServiceProvider);
  if (service == null) return const Stream.empty();
  return service.getTopScores(animalId);
});

final globalLeaderboardProvider = FutureProvider<List<UserProfile>>((ref) async {
  final repo = ref.watch(profileRepositoryProvider);
  return repo.getTopGlobalUsers();
});

class LeaderboardNotifier extends StateNotifier<AsyncValue<void>> {
  final LeaderboardService? _service;

  LeaderboardNotifier(this._service) : super(const AsyncValue.data(null));

  Future<void> submitScore({
    required String animalId,
    required LeaderboardEntry entry,
  }) async {
    if (_service == null) return;
    state = const AsyncValue.loading();
    try {
      await _service!.submitScore(animalId: animalId, entry: entry);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final leaderboardNotifierProvider = StateNotifierProvider<LeaderboardNotifier, AsyncValue<void>>((ref) {
  return LeaderboardNotifier(ref.watch(leaderboardServiceProvider));
});
