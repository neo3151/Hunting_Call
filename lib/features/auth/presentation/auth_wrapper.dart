import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hunting_calls_perfection/di_providers.dart';
import '../../profile/presentation/controllers/profile_controller.dart';
import '../../onboarding/presentation/controllers/onboarding_controller.dart';
import 'login_screen.dart';
import 'controllers/auth_controller.dart';
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
    if (_lastHandledUserId == userId || userId == 'guest') return;
    
    // Avoid double loading if already loading
    if (_isLoadingProfile) return;

    // Set immediately to prevent concurrent calls from rebuilds during awaits
    _lastHandledUserId = userId;

    if (mounted) setState(() => _isLoadingProfile = true);
    
    try {
      debugPrint("AuthWrapper: Loading profile for $userId");
      
      final profileRepo = ref.read(profileRepositoryProvider);
      
      // Check 1: Profile notifier might already have a profile loaded
      final currentProfile = ref.read(profileNotifierProvider).profile;
      if (currentProfile != null && currentProfile.id != 'guest') {
        debugPrint("AuthWrapper: ✅ Profile already loaded: ${currentProfile.name} (${currentProfile.id})");
        return;
      }
      
      // Check 2: Try to find profile by Firebase UID
      final profile = await profileRepo.getProfile(userId);
      if (profile.id != 'guest') {
        debugPrint("AuthWrapper: ✅ Profile found by UID: ${profile.name}");
        await ref.read(profileNotifierProvider.notifier).loadProfile(userId);
        return;
      }
      
      debugPrint("AuthWrapper: ⚠️ No profile found for $userId — user needs to create one via login screen.");
      
    } catch (e, stack) {
      debugPrint("AuthWrapper: Error: $e");
      debugPrint("Stack: $stack");
      // Reset on error so user can retry if needed
      _lastHandledUserId = null;
    } finally {
      if (mounted) {
        setState(() => _isLoadingProfile = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final _ = ref.read(onboardingProvider); // Use read or watch? Watch is better for changes.
    // onboardingProvider seems to be a StateProvider or similar.

    return authState.when(
      data: (user) {
        debugPrint("AuthWrapper: data received. user: ${user?.id}");
        
        if (user == null) {
          _lastHandledUserId = null;
          // Reset profile state to prevent session bleed
          ref.read(profileNotifierProvider.notifier).reset();
          debugPrint("AuthWrapper: user is null. Returning LoginScreen.");
          return const LoginScreen();
        }

        final userId = user.id;
        
        // Load profile before showing home screen
        if (_lastHandledUserId != userId) {
             WidgetsBinding.instance.addPostFrameCallback((_) {
              _loadProfile(userId);
            });
        }
        
        if (_isLoadingProfile) {
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
        
        // Check onboarding (using ref.watch to rebuild if it changes)
        final onb = ref.watch(onboardingProvider);
        if (!onb) {
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
           // This might cause infinite loop with AsyncNotifier if not careful, 
           // but mapped stream should handle nulls as data(null).
           // Error usually means stream error.
           WidgetsBinding.instance.addPostFrameCallback((_) {
             ref.invalidate(authControllerProvider);
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
                  onPressed: () => ref.invalidate(authControllerProvider),
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

