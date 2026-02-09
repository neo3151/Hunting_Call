import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/providers.dart';
import 'login_screen.dart';
import '../../onboarding/presentation/onboarding_screen.dart';
import '../../home/presentation/home_screen.dart';

/// Watches auth state and shows LoginScreen, OnboardingScreen, or HomeScreen accordingly
class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final hasSeenOnboarding = ref.watch(onboardingProvider);

    return authState.when(
      data: (userId) {
        print("AuthWrapper: data received. userId: $userId");
        if (userId == null) {
          print("AuthWrapper: userId is null. Returning LoginScreen.");
          return const LoginScreen();
        }
        
        if (!hasSeenOnboarding) {
          print("AuthWrapper: Onboarding not seen. Returning OnboardingScreen.");
          return const OnboardingScreen();
        }
        
        print("AuthWrapper: User authenticated and onboarding seen. Returning HomeScreen($userId).");
        return HomeScreen(userId: userId);
      },
      loading: () => const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, stack) {
        // Automatically retry once if it's the "User signed out" error on Linux
        final errorStr = error.toString();
        if (errorStr.contains('User signed out') || errorStr.contains('SignedOutException')) {
          print("AuthWrapper: Detected signed out error ($errorStr). Invalidating provider to force retry.");
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
