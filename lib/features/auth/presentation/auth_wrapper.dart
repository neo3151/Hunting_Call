import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/providers.dart';
import 'login_screen.dart';
import '../../onboarding/presentation/onboarding_screen.dart';
import '../../home/presentation/home_screen.dart';

/// Watches auth state and shows LoginScreen, OnboardingScreen, or HomeScreen.
/// Profile creation is handled by LoginScreen - this only loads existing profiles.
class AuthWrapper extends ConsumerStatefulWidget {
  const AuthWrapper({super.key});

  @override
  ConsumerState<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends ConsumerState<AuthWrapper> {
  bool _isLoadingProfile = false;
  String? _lastHandledUserId;

  Future<void> _loadProfile(String userId) async {
    if (_lastHandledUserId == userId) return;
    
    setState(() => _isLoadingProfile = true);
    
    try {
      debugPrint("AuthWrapper: Loading profile for $userId");
      
      final profileRepo = ref.read(profileRepositoryProvider);
      
      // Check 1: Profile notifier might already have a profile loaded
      // (login screen calls loadProfile(p.id) when tapping a card)
      final currentProfile = ref.read(profileNotifierProvider).profile;
      if (currentProfile != null && currentProfile.id != 'guest') {
        debugPrint("AuthWrapper: ✅ Profile already loaded: ${currentProfile.name}");
        _lastHandledUserId = userId;
        return;
      }
      
      // Check 2: Try to find profile by Firebase UID
      final profile = await profileRepo.getProfile(userId);
      if (profile.id != 'guest') {
        debugPrint("AuthWrapper: ✅ Profile found by UID: ${profile.name}");
        await ref.read(profileNotifierProvider.notifier).loadProfile(userId);
        _lastHandledUserId = userId;
        return;
      }
      
      // Check 3: Wait a bit more and retry (for Google sign-in creating profile)
      for (int i = 0; i < 5; i++) {
        await Future.delayed(const Duration(milliseconds: 500));
        final retryProfile = await profileRepo.getProfile(userId);
        if (retryProfile.id != 'guest') {
          debugPrint("AuthWrapper: ✅ Profile found on retry: ${retryProfile.name}");
          await ref.read(profileNotifierProvider.notifier).loadProfile(userId);
          _lastHandledUserId = userId;
          return;
        }
      }
      
      debugPrint("AuthWrapper: ⚠️ No profile found after all checks");
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
        
        // Load profile before showing home screen
        if (_lastHandledUserId != userId || _isLoadingProfile) {
          if (!_isLoadingProfile) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _loadProfile(userId);
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
