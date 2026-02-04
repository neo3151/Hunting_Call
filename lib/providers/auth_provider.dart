import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import '../features/auth/domain/auth_repository.dart';

/// Provides the AuthRepository instance
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return GetIt.I<AuthRepository>();
});

/// Tracks the current authenticated user ID
final authStateProvider = StreamProvider<String?>((ref) {
  final authRepo = ref.watch(authRepositoryProvider);
  return authRepo.onAuthStateChanged;
});

/// Notifier for auth actions (sign in, sign out)
class AuthNotifier extends Notifier<AsyncValue<String?>> {
  @override
  AsyncValue<String?> build() {
    return ref.watch(authStateProvider);
  }

  Future<void> signIn(String userId) async {
    state = const AsyncValue.loading();
    try {
      await ref.read(authRepositoryProvider).signIn(userId);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> signOut() async {
    state = const AsyncValue.loading();
    try {
      await ref.read(authRepositoryProvider).signOut();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final authNotifierProvider = NotifierProvider<AuthNotifier, AsyncValue<String?>>(() {
  return AuthNotifier();
});
