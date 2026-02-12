import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/sign_in.dart';
import '../../domain/usecases/sign_in_anonymously.dart';
import '../../domain/usecases/sign_in_with_google.dart';
import '../../domain/usecases/sign_out.dart';
import '../../domain/usecases/get_auth_state_stream.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../data/datasources/firebase_auth_data_source.dart';
import '../../../../providers/profile_provider.dart';
import 'package:get_it/get_it.dart';

// --- Dependency Injection via Riverpod ---

// 1. Data Sources
final authRemoteDataSourceProvider = Provider((ref) => FirebaseAuthDataSource());

// 2. Repositories
final authRepositoryImplProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(remoteDataSource: ref.watch(authRemoteDataSourceProvider));
});

// Helper provider for UI to check if we are in cloud mode
final firebaseEnabledProvider = Provider<bool>((ref) {
  return !ref.watch(authRepositoryImplProvider).isMock;
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return ref.watch(authRepositoryImplProvider);
});

// 3. Use Cases
final signInAnonymouslyUseCaseProvider = Provider((ref) {
  return SignInAnonymously(ref.watch(authRepositoryImplProvider));
});

final signInWithGoogleUseCaseProvider = Provider((ref) {
  return SignInWithGoogle(
    authRepository: ref.watch(authRepositoryImplProvider),
    profileRepository: GetIt.I(),
  );
});

final signInUseCaseProvider = Provider((ref) {
  return SignIn(ref.watch(authRepositoryImplProvider));
});

final signOutUseCaseProvider = Provider((ref) {
  return SignOut(ref.watch(authRepositoryImplProvider));
});

final getAuthStateStreamUseCaseProvider = Provider((ref) {
  return GetAuthStateStream(ref.watch(authRepositoryImplProvider));
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
      debugPrint('AuthController: Resetting profile state before sign-out');
      ref.read(profileNotifierProvider.notifier).reset();
      
      final useCase = ref.read(signOutUseCaseProvider);
      await useCase();
      // State updates automatically via stream
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
