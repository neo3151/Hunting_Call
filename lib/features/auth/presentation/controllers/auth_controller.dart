import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:outcall/features/auth/domain/entities/auth_user.dart';
import 'package:outcall/features/auth/domain/usecases/sign_in.dart';
import 'package:outcall/features/auth/domain/usecases/sign_in_anonymously.dart';
import 'package:outcall/features/auth/domain/usecases/sign_in_with_google.dart';
import 'package:outcall/features/auth/domain/usecases/sign_in_with_email.dart';
import 'package:outcall/features/auth/domain/usecases/sign_up_with_email.dart';
import 'package:outcall/features/auth/domain/usecases/send_password_reset_email.dart';
import 'package:outcall/features/auth/domain/usecases/sign_out.dart';
import 'package:outcall/features/auth/domain/usecases/get_auth_state_stream.dart';
import 'package:outcall/features/profile/presentation/controllers/profile_controller.dart';
import 'package:outcall/di_providers.dart';
import 'package:outcall/core/utils/app_logger.dart';
import 'package:outcall/core/services/logger/logger_service.dart';

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

final signInWithEmailUseCaseProvider = Provider((ref) {
  return SignInWithEmail(ref.watch(authRepositoryProvider));
});

final signUpWithEmailUseCaseProvider = Provider((ref) {
  return SignUpWithEmail(ref.watch(authRepositoryProvider));
});

final sendPasswordResetEmailUseCaseProvider = Provider((ref) {
  return SendPasswordResetEmail(ref.watch(authRepositoryProvider));
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
      ref.read(loggerServiceProvider).log('Attempting sign in anonymously');
      final useCase = ref.read(signInAnonymouslyUseCaseProvider);
      await useCase();
      
      // EAGER LOAD: Reach out and grab the profile immediately after auth success.
      final currentUser = await ref.read(authRepositoryProvider).currentUser;
      if (currentUser != null) {
        AppLogger.d('AuthController: Eagerly loading profile for Anonymous user ${currentUser.id}');
        await ref.read(profileNotifierProvider.notifier).loadProfile(currentUser.id);
      }

      ref.read(loggerServiceProvider).log('Signed in anonymously successfully');
      // State updates automatically via stream
    } catch (e, st) {
      ref.read(loggerServiceProvider).recordError(e, st, reason: 'Anonymous sign in failed');
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> signInWithGoogle() async {
    state = const AsyncValue.loading();
    try {
      ref.read(loggerServiceProvider).log('Attempting sign in with Google');
      final useCase = ref.read(signInWithGoogleUseCaseProvider);
      await useCase();
      
      // EAGER LOAD: Reach out and grab the profile immediately after auth success.
      // This "pre-warms" the ProfileNotifier so AuthWrapper finds it instantly.
      final currentUser = await ref.read(authRepositoryProvider).currentUser;
      if (currentUser != null) {
        AppLogger.d('AuthController: Eagerly loading profile for Google user ${currentUser.id}');
        await ref.read(profileNotifierProvider.notifier).loadProfile(currentUser.id);
      }
      
      ref.read(loggerServiceProvider).log('Signed in with Google successfully');
      // State updates automatically via stream
    } catch (e, st) {
      ref.read(loggerServiceProvider).recordError(e, st, reason: 'Google sign in failed');
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> signInWithEmail(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      ref.read(loggerServiceProvider).log('Attempting sign in with Email ($email)');
      final useCase = ref.read(signInWithEmailUseCaseProvider);
      await useCase(email, password);
      
      // EAGER LOAD: Reach out and grab the profile immediately after auth success.
      final currentUser = await ref.read(authRepositoryProvider).currentUser;
      if (currentUser != null) {
        AppLogger.d('AuthController: Eagerly loading profile for Email user ${currentUser.id}');
        await ref.read(profileNotifierProvider.notifier).loadProfile(currentUser.id);
      }

      ref.read(loggerServiceProvider).log('Signed in with Email successfully');
    } catch (e, st) {
      final error = _normalizeAuthError(e);
      ref.read(loggerServiceProvider).recordError(error, st, reason: 'Email sign in failed');
      state = const AsyncValue.data(null); // Revert to unauthenticated data state to avoid global error screen
      throw error; // Throw normalized error to be caught by UI
    }
  }

  Future<void> signUpWithEmail(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final useCase = ref.read(signUpWithEmailUseCaseProvider);
      await useCase(email, password);
    } catch (e) {
      final error = _normalizeAuthError(e);
      state = const AsyncValue.data(null);
      throw error;
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    // We don't change state to loading here because it's usually a background action 
    // that doesn't sign the user in or out.
    try {
      final useCase = ref.read(sendPasswordResetEmailUseCaseProvider);
      await useCase(email);
    } catch (e) {
      throw _normalizeAuthError(e);
    }
  }

  Object _normalizeAuthError(Object e) {
    final errorStr = e.toString();
    // Normalise Firedart/REST errors to Firebase SDK style strings
    // so the LoginScreen catches them properly.
    if (errorStr.contains('EMAIL_EXISTS')) return Exception('email-already-in-use');
    if (errorStr.contains('INVALID_PASSWORD')) return Exception('invalid-credential');
    if (errorStr.contains('EMAIL_NOT_FOUND')) return Exception('invalid-credential');
    if (errorStr.contains('WEAK_PASSWORD')) return Exception('weak-password');
    return e;
  }

  Future<void> signIn(String userId) async {
    state = const AsyncValue.loading();
    try {
      final useCase = ref.read(signInUseCaseProvider);
      await useCase(userId);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> signOut() async {
    state = const AsyncValue.loading();
    try {
      // Clear the current profile BEFORE signing out to prevent session bleed
      AppLogger.d('AuthController: Resetting profile state before sign-out');
      ref.read(loggerServiceProvider).log('Attempting sign out');
      ref.read(profileNotifierProvider.notifier).reset();
      
      final useCase = ref.read(signOutUseCaseProvider);
      await useCase();
      ref.read(loggerServiceProvider).log('Signed out successfully');
      // State updates automatically via stream
    } catch (e, st) {
      ref.read(loggerServiceProvider).recordError(e, st, reason: 'Sign out failed');
      state = AsyncValue.error(e, st);
    }
  }
}
