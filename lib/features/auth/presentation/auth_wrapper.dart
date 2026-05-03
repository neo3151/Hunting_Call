import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:outcall/core/utils/app_logger.dart';
import 'package:outcall/core/widgets/main_shell.dart';
import 'package:outcall/core/widgets/update_required_screen.dart';
import 'package:outcall/di_providers.dart';
import 'package:outcall/features/auth/presentation/controllers/auth_controller.dart';
import 'package:outcall/features/auth/presentation/login_screen.dart';
import 'package:outcall/features/onboarding/presentation/controllers/onboarding_controller.dart';
import 'package:outcall/features/onboarding/presentation/onboarding_screen.dart';
import 'package:outcall/features/profile/presentation/controllers/profile_controller.dart';
import 'package:outcall/core/theme/app_colors.dart';

/// Watches auth state and shows LoginScreen, OnboardingScreen, or HomeScreen.
/// Profile creation is handled by LoginScreen - this only loads existing profiles.
class AuthWrapper extends ConsumerStatefulWidget {
  const AuthWrapper({super.key});

  @override
  ConsumerState<AuthWrapper> createState() => _AuthWrapperState();
}

enum VersionCheckStatus { pending, ok, required }

class _AuthWrapperState extends ConsumerState<AuthWrapper> {
  VersionCheckStatus _versionStatus = VersionCheckStatus.pending;
  bool _showLoadingUI = false;
  Timer? _loadingTimer;

  @override
  void initState() {
    super.initState();
    _performVersionCheck();
  }

  @override
  void dispose() {
    _loadingTimer?.cancel();
    super.dispose();
  }

  Future<void> _performVersionCheck() async {
    try {
      final service = ref.read(versionCheckServiceProvider);
      final isRequired = await service.isUpdateRequired();
      if (mounted) {
        setState(() => _versionStatus = isRequired ? VersionCheckStatus.required : VersionCheckStatus.ok);
      }
    } catch (e) {
      if (mounted) setState(() => _versionStatus = VersionCheckStatus.ok);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_versionStatus == VersionCheckStatus.required) return const UpdateRequiredScreen();
    if (_versionStatus == VersionCheckStatus.pending) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final authState = ref.watch(authControllerProvider);
    final onboardingAsync = ref.watch(onboardingProvider);
    final profileState = ref.watch(profileNotifierProvider);

    // REACTIVE TRIGGER: Kick off profile loading and manage the "Grace Period" timer
    ref.listen(authControllerProvider, (previous, next) {
      next.whenData((user) {
        if (user != null) {
          // Read the *current* state, not the state from the build method closure
          final currentProfileState = ref.read(profileNotifierProvider);
          
          // 1. Kick off the load only if we don't have THIS user's profile and aren't already loading
          if (currentProfileState.profile?.id != user.id && !currentProfileState.isProfileLoading) {
            ref.read(profileNotifierProvider.notifier).loadProfile(user.id);
            
            // 2. Start a "Grace Period" timer. We only show the Loading UI if 
            // it takes LONGER than 500ms to load the profile.
            _loadingTimer?.cancel();
            setState(() => _showLoadingUI = false);
            _loadingTimer = Timer(const Duration(milliseconds: 500), () {
              if (mounted) setState(() => _showLoadingUI = true);
            });
          }
        } else {
          // Clean up on sign out
          final currentProfileState = ref.read(profileNotifierProvider);
          if (currentProfileState.profile != null || currentProfileState.isProfileLoading) {
             _loadingTimer?.cancel();
             setState(() => _showLoadingUI = false);
             ref.read(profileNotifierProvider.notifier).reset();
          }
        }
      });
    });

    return authState.when(
      data: (user) {
        return onboardingAsync.when(
          data: (hasSeenOnboarding) {
            if (!hasSeenOnboarding) return const OnboardingScreen();
            if (user == null) return const LoginScreen();

            // IF PROFILE NOT READY: Decide between Login Screen (Grace Period) or Loading Screen
            if (profileState.profile == null || profileState.isProfileLoading) {
              if (!_showLoadingUI) return const LoginScreen();
              
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

            return MainShell(userId: user.id);
          },
          loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
          error: (e, _) => _buildErrorScreen(e.toString()),
        );
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, st) => _buildErrorScreen(e.toString()),
    );
  }

  Widget _buildErrorScreen(String error) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text('Auth Error: $error'),
            TextButton(
              onPressed: () => ref.invalidate(authControllerProvider),
              child: const Text('RETRY'),
            ),
          ],
        ),
      ),
    );
  }
}
