import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../providers/providers.dart';
import 'login_screen.dart';
import '../../onboarding/presentation/onboarding_screen.dart';
import '../../home/presentation/home_screen.dart';

/// Watches auth state and shows LoginScreen, OnboardingScreen, or HomeScreen accordingly.
/// Also handles profile creation for Google Sign-In users.
class AuthWrapper extends ConsumerStatefulWidget {
  const AuthWrapper({super.key});

  @override
  ConsumerState<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends ConsumerState<AuthWrapper> {
  bool _isLoadingProfile = false;
  String? _lastHandledUserId;

  Future<void> _ensureProfileExists(String userId) async {
    // Avoid re-running for the same user
    if (_lastHandledUserId == userId) return;
    
    setState(() => _isLoadingProfile = true);
    
    try {
      debugPrint("AuthWrapper: Ensuring profile exists for $userId");
      
      // Wait for Firebase user data to fully load (email might not be available immediately)
      var firebaseUser = FirebaseAuth.instance.currentUser;
      var userEmail = firebaseUser?.email;
      
      // Retry up to 5 times with 200ms delay if email is null
      for (int i = 0; i < 5 && userEmail == null; i++) {
        debugPrint("🔍 Waiting for Firebase user email... attempt ${i + 1}");
        await Future.delayed(const Duration(milliseconds: 200));
        await firebaseUser?.reload();
        firebaseUser = FirebaseAuth.instance.currentUser;
        userEmail = firebaseUser?.email;
      }
      
      debugPrint("🔍 Firebase user info:");
      debugPrint("🔍   UID: ${firebaseUser?.uid}");
      debugPrint("🔍   Email: $userEmail");
      debugPrint("🔍   Display name: ${firebaseUser?.displayName}");
      
      // Check if profile exists by user ID
      final profileRepo = ref.read(profileRepositoryProvider);
      final existingProfile = await profileRepo.getProfile(userId);
      
      if (existingProfile.id != 'guest') {
        debugPrint("AuthWrapper: Profile exists by ID: ${existingProfile.name}");
        await ref.read(profileNotifierProvider.notifier).loadProfile(userId);
        _lastHandledUserId = userId;
        return;
      }
      
      // Check if profile exists by email
      if (userEmail != null) {
        final allProfiles = await profileRepo.getAllProfiles();
        final profileByEmail = allProfiles.where((p) => p.email == userEmail).firstOrNull;
        
        if (profileByEmail != null) {
          debugPrint("AuthWrapper: Found existing profile by email: ${profileByEmail.name}");
          await ref.read(profileNotifierProvider.notifier).loadProfile(profileByEmail.id);
          _lastHandledUserId = userId;
          return;
        }
      }
      
      // No existing profile - create new one
      // Use email prefix as display name if displayName is null
      String displayName = firebaseUser?.displayName ?? 
                          userEmail?.split('@').first ?? 
                          'Hunter';
      
      debugPrint("🔍 Final display name: $displayName");
      debugPrint("AuthWrapper: Creating profile: $displayName ($userId) with email: $userEmail");
      
      await profileRepo.createProfile(displayName, id: userId, birthday: null, email: userEmail);
      
      await ref.read(profileNotifierProvider.notifier).loadProfile(userId);
      debugPrint("AuthWrapper: Profile created and loaded");
      
      _lastHandledUserId = userId;
    } catch (e, stack) {
      debugPrint("AuthWrapper: Error: $e");
      debugPrint("Stack: $stack");
    } finally {
      if (mounted) {
        setState(() => _isLoadingProfile = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final hasSeenOnboarding = ref.watch(onboardingProvider);

    return authState.when(
      data: (userId) {
        debugPrint("AuthWrapper: data received. userId: $userId");
        if (userId == null) {
          _lastHandledUserId = null;
          debugPrint("AuthWrapper: userId is null. Returning LoginScreen.");
          return const LoginScreen();
        }
        
        // Ensure profile exists before showing home screen
        if (_lastHandledUserId != userId || _isLoadingProfile) {
          if (!_isLoadingProfile) {
            // Trigger profile loading
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _ensureProfileExists(userId);
            });
          }
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Setting up your profile...'),
                ],
              ),
            ),
          );
        }
        
        if (!hasSeenOnboarding) {
          debugPrint("AuthWrapper: Onboarding not seen. Returning OnboardingScreen.");
          return const OnboardingScreen();
        }
        
        debugPrint("AuthWrapper: User authenticated and onboarding seen. Returning HomeScreen($userId).");
        return HomeScreen(userId: userId);
      },
      loading: () => const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, stack) {
        final errorStr = error.toString();
        if (errorStr.contains('User signed out') || errorStr.contains('SignedOutException')) {
          debugPrint("AuthWrapper: Detected signed out error ($errorStr). Invalidating provider to force retry.");
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ref.invalidate(authStateProvider);
          });
        }
        
        return Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                Text('Auth Error: $error'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.invalidate(authStateProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
