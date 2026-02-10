import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/widgets/background_wrapper.dart';
import '../../../providers/providers.dart';
import '../../profile/domain/profile_model.dart';
import '../../settings/presentation/privacy_policy_screen.dart';
import 'package:intl/intl.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  @override
  void initState() {
    super.initState();
    // Load profiles on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(profileNotifierProvider.notifier).loadAllProfiles();
    });
  }

  Future<void> _createNewProfile() async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _CreateProfileSheet(),
    );

    if (result != null) {
      final name = result['name'] as String;
      final birthday = result['birthday'] as DateTime?;

    if (name.isNotEmpty) {
      final authRepo = ref.read(authRepositoryProvider);
      
      try {
        // 1. Sign in anonymously first
        await authRepo.signInAnonymously();
        
        // 2. Get the technical UID
        final uid = authRepo.authenticatedUserId;
        
        if (uid != null) {
          // 3. Create the profile with that UID
          await ref.read(profileNotifierProvider.notifier).createProfile(name, id: uid, birthday: birthday);
        } else {
          throw Exception("Could not retrieve user ID after sign-in.");
        }
      } catch (e) {
        if (mounted) {
          debugPrint("Profile creation failed: $e");
          String message = "Authentication failed. Please check your internet connection.";
          if (e.toString().contains('unknown-error')) {
            message = "Anonymous sign-in failed. Please ensure 'Anonymous' auth is enabled in your Firebase Console.";
          }
           ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(
               content: Text(message),
               backgroundColor: Colors.redAccent,
               behavior: SnackBarBehavior.floating,
             )
           );
        }
      }
    }
  }
}

  Future<void> _signInWithGoogle() async {
    try {
      debugPrint('🔐 Starting Google Sign-In...');
      
      // Call signInWithGoogle and capture the user info
      final userInfo = await ref.read(authRepositoryProvider).signInWithGoogle();
      final email = userInfo['email'];
      final displayName = userInfo['displayName'];
      final userId = ref.read(authRepositoryProvider).currentUserId;
      
      debugPrint('✅ Google Sign-In completed');
      debugPrint('📧 Email: $email');
      debugPrint('👤 Display Name: $displayName');
      debugPrint('🆔 User ID: $userId');
      
      if (userId == null) {
        debugPrint('❌ No user ID after sign-in!');
        return;
      }
      
      // Create profile RIGHT HERE where we have the email
      // This runs AFTER signInWithProvider returns, so AuthWrapper may have
      // already fired. But we create the profile here with the correct data.
      final profileRepo = ref.read(profileRepositoryProvider);
      final existingProfile = await profileRepo.getProfile(userId);
      
      if (existingProfile.id != 'guest') {
        debugPrint('✅ Profile already exists: ${existingProfile.name}');
        await ref.read(profileNotifierProvider.notifier).loadProfile(userId);
        return;
      }
      
      // Check by email
      if (email != null) {
        final allProfiles = await profileRepo.getAllProfiles();
        final profileByEmail = allProfiles.where((p) => p.email == email).firstOrNull;
        if (profileByEmail != null) {
          debugPrint('✅ Found profile by email: ${profileByEmail.name}');
          await ref.read(profileNotifierProvider.notifier).loadProfile(profileByEmail.id);
          return;
        }
      }
      
      // No profile exists - create one with the Google data
      final profileName = displayName ?? email?.split('@').first ?? 'Hunter';
      debugPrint('🆕 Creating profile: $profileName with email: $email');
      
      await profileRepo.createProfile(profileName, id: userId, birthday: null, email: email);
      await ref.read(profileNotifierProvider.notifier).loadProfile(userId);
      debugPrint('✅ Profile created and loaded!');
      
    } catch (e, stackTrace) {
      debugPrint("❌ Google Sign-In failed: $e");
      debugPrint("Stack trace: $stackTrace");
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Google Sign-In failed: $e"), backgroundColor: Colors.red)
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileNotifierProvider);
    final profiles = profileState.allProfiles;
    final isLoading = profileState.isLoading;

    debugPrint("LoginScreen: Building. isLoading=$isLoading, profiles.length=${profiles.length}, error=${profileState.error}");

    return Scaffold(
      body: BackgroundWrapper(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: constraints.maxHeight),
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Icon(Icons.forest_rounded, size: 80, color: Color(0xFF81C784)),
                              const SizedBox(height: 24),
                              Text(
                                'HUNTING\nCALLS',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.oswald(
                                  fontSize: 48,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  height: 1.0,
                                  letterSpacing: 2.0,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'MASTER THE WILD',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.lato(
                                  fontSize: 16,
                                  color: Colors.white70,
                                  letterSpacing: 4.0,
                                ),
                              ),
                            const SizedBox(height: 48),
                              // === MOBILE: Google Sign-In primary, no shared profile list ===
                              if (!Platform.isWindows && !Platform.isLinux) ...[
                                OutlinedButton.icon(
                                  onPressed: _signInWithGoogle,
                                  icon: const Icon(Icons.login, color: Colors.white, size: 24),
                                  label: Text(
                                    "SIGN IN WITH GOOGLE",
                                    style: GoogleFonts.oswald(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                                    padding: const EdgeInsets.symmetric(vertical: 18),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.2))),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 16),
                                      child: Text("OR", style: GoogleFonts.lato(color: Colors.white38, fontSize: 12)),
                                    ),
                                    Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.2))),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: _createNewProfile,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF81C784),
                                    foregroundColor: const Color(0xFF0F1E12),
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    elevation: 0,
                                  ),
                                  child: Text('PLAY AS GUEST', style: GoogleFonts.oswald(fontWeight: FontWeight.bold, letterSpacing: 1.0, fontSize: 16)),
                                ),
                              ],
                              // === DESKTOP: Keep profile list for development ===
                              if (Platform.isWindows || Platform.isLinux) ...[
                                Text(
                                   "WHO IS HUNTING?",
                                   style: GoogleFonts.lato(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 16),
                                ConstrainedBox(
                                  constraints: const BoxConstraints(maxHeight: 200),
                                  child: isLoading
                                    ? const Center(child: CircularProgressIndicator(color: Colors.white))
                                    : profileState.error != null
                                      ? _buildErrorDisplay(profileState.error!)
                                      : profiles.isEmpty
                                        ? _buildEmptyState()
                                        : ListView.separated(
                                            shrinkWrap: true,
                                            physics: const NeverScrollableScrollPhysics(),
                                            itemCount: profiles.length,
                                            separatorBuilder: (_, __) => const SizedBox(height: 8),
                                            itemBuilder: (context, index) {
                                              final p = profiles[index];
                                              return _buildProfileCard(p);
                                            },
                                          ),
                                ),
                                const SizedBox(height: 24),
                                ElevatedButton(
                                  onPressed: _createNewProfile,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF81C784),
                                    foregroundColor: const Color(0xFF0F1E12),
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    elevation: 0,
                                  ),
                                  child: const Text('NEW HUNTER PROFILE', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                                ),
                              ],
                              const SizedBox(height: 32),
                              Center(
                                child: TextButton(
                                  onPressed: () {
                                    Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()));
                                  },
                                  child: Text(
                                    "Privacy Policy", 
                                    style: GoogleFonts.lato(
                                      color: Colors.white38, 
                                      decoration: TextDecoration.underline,
                                      fontSize: 12
                                    )
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorDisplay(String error) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.redAccent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline, color: Colors.redAccent),
          const SizedBox(height: 8),
          Text(
            "Failed to load profiles: $error",
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => ref.read(profileNotifierProvider.notifier).loadAllProfiles(),
            child: const Text("RETRY", style: TextStyle(color: Colors.greenAccent)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1),
      ),
      child: const Text(
        "No profiles yet.\nCreate one to get started!",
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.white54, fontSize: 14),
      ),
    );
  }

  Widget _buildProfileCard(UserProfile p) {
    return InkWell(
      onTap: () {
        debugPrint("LoginScreen: Tapped profile ${p.name} (${p.id})");
        try {
          // 1. Set the auth state (this triggers the transition)
          ref.read(authRepositoryProvider).signIn(p.id);
          debugPrint("LoginScreen: signIn called for ${p.id}");
          
          // 2. Pre-emptively load the profile so HomeScreen has it immediately
          ref.read(profileNotifierProvider.notifier).loadProfile(p.id);
          debugPrint("LoginScreen: signIn called for ${p.id}");
        } catch (e, stack) {
          debugPrint("LoginScreen: ERROR tapping profile: $e\\n$stack");
        }
      },
      child: Container(
        constraints: const BoxConstraints(minHeight: 72),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF2D5F3D),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF81C784).withValues(alpha: 0.3), width: 1),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: const Color(0xFF81C784),
              foregroundColor: const Color(0xFF0F1E12),
              child: Text(p.name[0].toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.name, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  Text(
                    "${p.totalCalls} calls • ${p.averageScore.toStringAsFixed(0)}% avg",
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white54, size: 24),
          ],
        ),
      ),
    );
  }
}

class _CreateProfileSheet extends StatefulWidget {
  const _CreateProfileSheet();

  @override
  State<_CreateProfileSheet> createState() => _CreateProfileSheetState();
}

class _CreateProfileSheetState extends State<_CreateProfileSheet> {
  final _controller = TextEditingController();
  DateTime? _birthday;
  bool _isValid = false;
  
  /// Minimum characters required for a valid profile name
  static const int _minNameLength = 2;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_validateInput);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _validateInput() {
    final isValid = _controller.text.trim().length >= _minNameLength && _birthday != null;
    if (isValid != _isValid) {
      setState(() => _isValid = isValid);
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 18)), // Default to 18 years ago
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF81C784),
              onPrimary: Colors.black,
              surface: Color(0xFF1B3B24),
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: const Color(0xFF0F1E12),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _birthday = picked;
      });
      _validateInput();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        top: 24, left: 24, right: 24
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF1B3B24),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Create Profile', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            autofocus: true,
            style: const TextStyle(color: Colors.white),
            cursorColor: Colors.greenAccent,
            maxLength: 30,
            decoration: InputDecoration(
              labelText: 'Hunter Name',
              labelStyle: const TextStyle(color: Colors.white70),
              helperText: 'At least $_minNameLength characters',
              helperStyle: const TextStyle(color: Colors.white54),
              counterStyle: const TextStyle(color: Colors.white54),
              enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.3))),
              focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.greenAccent)),
              errorBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.redAccent)),
              focusedErrorBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.redAccent)),
              errorText: _controller.text.isNotEmpty && !_isValid 
                  ? 'Name must be at least $_minNameLength characters' 
                  : null,
            ),
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: _selectDate,
            borderRadius: BorderRadius.circular(4),
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: 'Birthday',
                labelStyle: const TextStyle(color: Colors.white70),
                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.3))),
                errorBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.redAccent)),
                border: const OutlineInputBorder(),
                suffixIcon: const Icon(Icons.calendar_today, color: Colors.greenAccent),
              ),
              child: Text(
                _birthday == null 
                  ? 'Select Date' 
                  : DateFormat('MMM d, yyyy').format(_birthday!),
                style: TextStyle(
                  color: _birthday == null ? Colors.white54 : Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _isValid ? () => Navigator.pop(context, {
              'name': _controller.text.trim(),
              'birthday': _birthday,
            }) : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF81C784),
              foregroundColor: const Color(0xFF0F1E12),
              disabledBackgroundColor: Colors.grey.shade700,
              disabledForegroundColor: Colors.grey.shade400,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('START HUNTING'),
          ),
        ],
      ),
    );
  }
}
