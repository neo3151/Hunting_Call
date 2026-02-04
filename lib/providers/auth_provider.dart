import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/auth/domain/auth_repository.dart';
import '../features/auth/data/mock_auth_repository.dart';

/// Provides the AuthRepository instance
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return MockAuthRepository();
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
    // Listen to auth state changes
    ref.listen(authStateProvider, (previous, next) {
      state = next;
    });
    return const AsyncValue.loading();
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
