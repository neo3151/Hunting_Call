import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:outcall/features/leaderboard/domain/leaderboard_entry.dart';

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

class LeaderboardNotifier extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  Future<void> submitScore({
    required String animalId,
    required LeaderboardEntry entry,
  }) async {
    final service = ref.read(leaderboardServiceProvider);
    if (service == null) return;
    
    state = const AsyncValue.loading();
    try {
      await service.submitScore(animalId: animalId, entry: entry);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final leaderboardNotifierProvider = NotifierProvider<LeaderboardNotifier, AsyncValue<void>>(LeaderboardNotifier.new);
