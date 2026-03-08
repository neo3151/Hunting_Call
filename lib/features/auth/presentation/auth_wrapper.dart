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

/// Watches auth state and shows LoginScreen, OnboardingScreen, or HomeScreen.
/// Profile creation is handled by LoginScreen - this only loads existing profiles.
class AuthWrapper extends ConsumerStatefulWidget {
  const AuthWrapper({super.key});

  @override
  ConsumerState<AuthWrapper> createState() => _AuthWrapperState();
}

enum VersionCheckStatus { pending, ok, required }

class _AuthWrapperState extends ConsumerState<AuthWrapper> {
  bool _isLoadingProfile = false;
  String? _lastHandledUserId;
  VersionCheckStatus _versionStatus = VersionCheckStatus.pending;

  @override
  void initState() {
    super.initState();
    _performVersionCheck();
  }

  Future<void> _performVersionCheck() async {
    try {
      final service = ref.read(versionCheckServiceProvider);
      final isRequired = await service.isUpdateRequired();
      if (mounted) {
        setState(() {
          _versionStatus = isRequired ? VersionCheckStatus.required : VersionCheckStatus.ok;
        });
      }
    } catch (e) {
      AppLogger.d('AuthWrapper: Version check failed: $e');
      if (mounted) {
        setState(() => _versionStatus = VersionCheckStatus.ok); // Proceed anyway on error
      }
    }
  }

  Future<void> _loadProfile(String userId) async {
    if (_lastHandledUserId == userId || userId == 'guest') return;

    // Avoid double loading if already loading
    if (_isLoadingProfile) return;

    // Set immediately to prevent concurrent calls from rebuilds during awaits
    _lastHandledUserId = userId;

    if (mounted) setState(() => _isLoadingProfile = true);

    try {
      AppLogger.d('AuthWrapper: Loading profile for $userId');

      // Check 1: Profile notifier might already have a profile loaded
      final currentProfile = ref.read(profileNotifierProvider).profile;
      if (currentProfile != null && currentProfile.id != 'guest') {
        AppLogger.d(
            'AuthWrapper: ✅ Profile already loaded: ${currentProfile.name} (${currentProfile.id})');
        return;
      }

      // Check 2: Try to find profile by Firebase UID.
      // The profile may not exist yet because LoginScreen._createNewProfile
      // creates the auth account first (which triggers this rebuild) and
      // THEN writes the profile. Retry a few times to give it a chance.
      final profileRepo = ref.read(profileRepositoryProvider);
      const maxRetries = 5;
      for (int attempt = 1; attempt <= maxRetries; attempt++) {
        AppLogger.d('AuthWrapper: getProfile attempt $attempt/$maxRetries for $userId');
        try {
          final profile = await profileRepo.getProfile(userId);
          if (profile.id != 'guest') {
            AppLogger.d('AuthWrapper: ✅ Profile found by UID: ${profile.name}');
            await ref.read(profileNotifierProvider.notifier).loadProfile(userId);
            return;
          }
        } catch (e) {
          AppLogger.d('AuthWrapper: getProfile attempt $attempt failed: $e');
        }
        if (attempt < maxRetries) {
          AppLogger.d('AuthWrapper: Profile not found yet, waiting 1s before retry...');
          await Future.delayed(const Duration(seconds: 1));
          if (!mounted) return;
        }
      }

      AppLogger.d(
          'AuthWrapper: ⚠️ No profile found for $userId after $maxRetries attempts — showing guest fallback.');
    } catch (e, stack) {
      AppLogger.d('AuthWrapper: Error loading profile: $e');
      AppLogger.d('Stack: $stack');
      // Don't reset _lastHandledUserId — that causes infinite retry loops
    } finally {
      if (mounted) {
        setState(() => _isLoadingProfile = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_versionStatus == VersionCheckStatus.required) {
      return const UpdateRequiredScreen();
    }

    if (_versionStatus == VersionCheckStatus.pending) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Theme.of(context).primaryColor),
        ),
      );
    }

    final authState = ref.watch(authControllerProvider);
    final _ = ref.read(onboardingProvider); // Use read or watch? Watch is better for changes.
    // onboardingProvider seems to be a StateProvider or similar.

    return authState.when(
      data: (user) {
        AppLogger.d('AuthWrapper: data received. user: ${user?.id}');

        // 1. Check Onboarding First
        final onboardingState = ref.watch(onboardingProvider);

        return onboardingState.when(
          data: (hasSeenOnboarding) {
            if (!hasSeenOnboarding) {
              AppLogger.d('AuthWrapper: Onboarding not seen. Returning OnboardingScreen.');
              return const OnboardingScreen();
            }

            // 2. Handle Authentication
            if (user == null) {
              _lastHandledUserId = null;
              // Clean up profile notifier
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  ref.read(profileNotifierProvider.notifier).reset();
                }
              });
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

            AppLogger.d(
                'AuthWrapper: User authenticated and onboarding seen. Returning HomeScreen($userId).');
            return MainShell(userId: userId);
          },
          loading: () => const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          ),
          error: (error, stack) => Scaffold(
            body: Center(child: Text('Error loading app state: $error')),
          ),
        );
      },
      loading: () => const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, stack) {
        final errorStr = error.toString();
        if (errorStr.contains('User signed out') || errorStr.contains('SignedOutException')) {
          AppLogger.d(
              'AuthWrapper: Detected signed out error ($errorStr). Invalidating provider to force retry.');
          // This might cause infinite loop with AsyncNotifier if not careful,
          // but mapped stream should handle nulls as data(null).
          // Error usually means stream error.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ref.invalidate(authControllerProvider);
          });
        }

        return Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.cloud_off_rounded, color: Colors.orangeAccent, size: 64),
                  const SizedBox(height: 16),
                  Text(
                    "Network's drunk—try again?",
                    style: GoogleFonts.oswald(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: const Color(0xFF121212),
                    ),
                    onPressed: () => ref.invalidate(authControllerProvider),
                    child: Text('TRY AGAIN',
                        style: GoogleFonts.oswald(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
