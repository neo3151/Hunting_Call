import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/usecases/sign_in.dart';
import '../../domain/usecases/sign_in_anonymously.dart';
import '../../domain/usecases/sign_in_with_google.dart';
import '../../domain/usecases/sign_out.dart';
import '../../domain/usecases/get_auth_state_stream.dart';
import '../../../profile/presentation/controllers/profile_controller.dart';
import 'package:hunting_calls_perfection/di_providers.dart';
import 'package:hunting_calls_perfection/core/utils/app_logger.dart';

// --- Dependency Injection via Riverpod ---
// Auth repository is provided by di_providers.dart (platform-aware: Firebase/Firedart/Mock)

// Helper provider for UI to check if we are in cloud mode
final firebaseEnabledProvider = Provider<bool>((ref) {
  return !ref.watch(authRepositoryProvider).isMock;
});

// 3. Use Cases
final signInAnonymouslyUseCaseProvider = Provider((ref) {
  return SignInAnonymously(ref.watch(authRepositoryProvider));
});

final signInWithGoogleUseCaseProvider = Provider((ref) {
  return SignInWithGoogle(
    authRepository: ref.watch(authRepositoryProvider),
    profileRepository: ref.watch(profileRepositoryProvider),
  );
});

final signInUseCaseProvider = Provider((ref) {
  return SignIn(ref.watch(authRepositoryProvider));
});

final signOutUseCaseProvider = Provider((ref) {
  return SignOut(ref.watch(authRepositoryProvider));
});

final getAuthStateStreamUseCaseProvider = Provider((ref) {
  return GetAuthStateStream(ref.watch(authRepositoryProvider));
});

// --- Controller ---

final authControllerProvider = StreamNotifierProvider<AuthController, AuthUser?>(() {
  return AuthController();
});

class AuthController extends StreamNotifier<AuthUser?> {
  @override
  Stream<AuthUser?> build() {
    final getAuthStateStream = ref.watch(getAuthStateStreamUseCaseProvider);
    return getAuthStateStream();
  }

  Future<void> signInAnonymously() async {
    state = const AsyncValue.loading();
    try {
      final useCase = ref.read(signInAnonymouslyUseCaseProvider);
      await useCase();
      // State updates automatically via stream
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> signInWithGoogle() async {
    state = const AsyncValue.loading();
    try {
      final useCase = ref.read(signInWithGoogleUseCaseProvider);
      await useCase();
      // State updates automatically via stream
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> signIn(String userId) async {
    state = const AsyncValue.loading();
    try {
      final useCase = ref.read(signInUseCaseProvider);
      await useCase(userId);
      // State updates automatically via stream
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> signOut() async {
    state = const AsyncValue.loading();
    try {
      // Clear the current profile BEFORE signing out to prevent session bleed
      AppLogger.d('AuthController: Resetting profile state before sign-out');
      ref.read(profileNotifierProvider.notifier).reset();
      
      final useCase = ref.read(signOutUseCaseProvider);
      await useCase();
      // State updates automatically via stream
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
