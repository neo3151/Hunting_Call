import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hunting_calls_perfection/di_providers.dart';
import 'controllers/auth_controller.dart';

import '../../../core/widgets/background_wrapper.dart';
import '../../profile/presentation/controllers/profile_controller.dart';

import '../../settings/presentation/privacy_policy_screen.dart';
import 'package:intl/intl.dart';
import 'package:hunting_calls_perfection/core/utils/app_logger.dart';

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
    // Load profiles on init - REMOVED for Release (Privacy/Perf)
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   ref.read(profileNotifierProvider.notifier).loadAllProfiles();
    // });
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
      final email = result['email'] as String?;
      final password = result['password'] as String?;

      if (name.isNotEmpty) {
        // Capture providers BEFORE async gap to avoid "unmounted widget" errors
        final authRepo = ref.read(authRepositoryProvider);
        final profileNotifier = ref.read(profileNotifierProvider.notifier);
        final authNotifier = ref.read(authControllerProvider.notifier);

        try {
          String? safeUid;

          if (email != null && password != null) {
            // SILENT sign-up: creates the auth account WITHOUT emitting auth
            // state, so AuthWrapper doesn't rebuild yet. This gives us time
            // to write the profile to Firestore first.
            AppLogger.d('LoginScreen: Silent sign-up for $email...');
            safeUid = await authRepo.signUpSilent(email, password);
            AppLogger.d('LoginScreen: Silent sign-up complete. UID: $safeUid');
          } else {
            // Anonymous sign-in (no race issue since no profile to save)
            AppLogger.d('LoginScreen: Anonymous sign-in...');
            await authNotifier.signInAnonymously();
            final currentUser = await authRepo.currentUser;
            safeUid = currentUser?.id;
            AppLogger.d('LoginScreen: Anonymous UID: $safeUid');
          }

          if (safeUid != null) {
            // Create the profile in Firestore BEFORE triggering AuthWrapper
            AppLogger.d('LoginScreen: Creating profile for $safeUid...');
            await profileNotifier.createProfile(name, id: safeUid, birthday: birthday);
            AppLogger.d('LoginScreen: Profile created! Now emitting auth state...');

            // NOW emit auth state — AuthWrapper will rebuild and find the profile
            authRepo.emitAuthState();
          } else {
            throw Exception('Could not retrieve user ID after authentication.');
          }
        } catch (e) {
          AppLogger.d('Profile creation failed: $e');
          if (mounted) {
            String message = 'Profile creation failed. Please check your internet connection.';
            if (e.toString().contains('email-already-in-use')) {
              message = 'This email is already in use. Please log in instead.';
            } else if (e.toString().contains('weak-password')) {
              message = 'Password is too weak. Please use at least 6 characters.';
            } else if (e.toString().contains('OPERATION_NOT_ALLOWED')) {
              message = 'Email sign-up is disabled. Please enable it in Firebase Console.';
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

  Future<void> _signInWithEmail() async {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('Hunter Log In', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Enter your credentials to sync your hunting progress across devices.',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              autofocus: true,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Email Address',
                labelStyle: TextStyle(color: Colors.white54),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white30)),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.greenAccent)),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: passwordController,
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Password',
                labelStyle: TextStyle(color: Colors.white54),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white30)),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.greenAccent)),
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () async {
                  final email = emailController.text.trim();
                  if (email.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: const Text('Please enter your email address first.'), backgroundColor: Theme.of(context).primaryColor)
                    );
                    return;
                  }
                  try {
                    await ref.read(authControllerProvider.notifier).sendPasswordResetEmail(email);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Password reset email sent! Check your inbox.'), backgroundColor: Colors.green)
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to send reset email: $e'), backgroundColor: Colors.redAccent)
                      );
                    }
                  }
                },
                child: const Text('Forgot Password?', style: TextStyle(color: Colors.white54, fontSize: 12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () {
              if (emailController.text.isEmpty || passwordController.text.isEmpty) return;
              Navigator.pop(context, {
                'email': emailController.text.trim(),
                'password': passwordController.text.trimRight(), // Trim trailing spaces from copy-pastes
              });
            },
            child: const Text('LOG IN', style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (result != null) {
      final email = result['email']!;
      final password = result['password']!;
      
      if (!mounted) return;
      
      try {
        // Use the new secure auth method
        await ref.read(authControllerProvider.notifier).signInWithEmail(email, password);
        // AuthWrapper will handle navigation once state updates
      } catch (e) {
        AppLogger.d('❌ Email login failed: $e');
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(
               content: Text('Login failed: ${e.toString().contains('invalid-credential') ? 'Invalid email or password.' : e}'), 
               backgroundColor: Colors.redAccent
             )
           );
        }
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    try {
      // AppLogger.d('🔐 Starting Google Sign-In via AuthController...');
      
      // AuthController now handles:
      // 1. Sign in with Google
      // 2. Ensure profile exists (Create if needed)
      await ref.read(authControllerProvider.notifier).signInWithGoogle();
      
      // Success is handled by AuthWrapper watching the state change
      // AppLogger.d('✅ Google Sign-In triggered successfully');
      
    } catch (e, stackTrace) {
      AppLogger.d('❌ Google Sign-In failed: $e');
      AppLogger.d('Stack trace: $stackTrace');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Google Sign-In failed: $e'), backgroundColor: Colors.red)
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(profileNotifierProvider);

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
                              Icon(Icons.forest_rounded, size: 80, color: Theme.of(context).primaryColor),
                              const SizedBox(height: 24),
                              Text(
                                'OUTCALL',
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
                                'MASTER YOUR CALLS',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.lato(
                                  fontSize: 16,
                                  color: Colors.white70,
                                  letterSpacing: 4.0,
                                ),
                              ),
                            const SizedBox(height: 48),
                              // === LOGIN OPTIONS ===
                              // Google Sign-In (Mobile Only)
                              if (!Platform.isWindows && !Platform.isLinux) ...[
                                OutlinedButton.icon(
                                  onPressed: _signInWithGoogle,
                                  icon: const Icon(Icons.login, color: Colors.white, size: 24),
                                  label: Text(
                                    'SIGN IN WITH GOOGLE',
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
                              ],
                              
                              // Email Login (Desktop - Manual Sync)
                              if (Platform.isWindows || Platform.isLinux) ...[
                                OutlinedButton.icon(
                                  onPressed: _signInWithEmail,
                                  icon: const Icon(Icons.email_outlined, color: Colors.white, size: 24),
                                  label: Text(
                                    'LOG IN WITH EMAIL',
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
                              ],

                              const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.2))),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 16),
                                      child: Text('OR', style: GoogleFonts.lato(color: Colors.white38, fontSize: 12)),
                                    ),
                                    Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.2))),
                                  ],
                                ),
                              
                              const SizedBox(height: 16),
                              
                              // Create New Profile / Play as Guest
                              ElevatedButton(
                                onPressed: _createNewProfile,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Theme.of(context).primaryColor,
                                  foregroundColor: const Color(0xFF121212),
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  elevation: 0,
                                ),
                                child: Text(
                                  'NEW HUNTER PROFILE', 
                                  style: GoogleFonts.oswald(fontWeight: FontWeight.bold, letterSpacing: 1.0, fontSize: 16)
                                ),
                              ),
                              const SizedBox(height: 32),
                              Center(
                                child: TextButton(
                                  onPressed: () {
                                    Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()));
                                  },
                                  child: Text(
                                    'Privacy Policy', 
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
}

class _CreateProfileSheet extends StatefulWidget {
  const _CreateProfileSheet();

  @override
  State<_CreateProfileSheet> createState() => _CreateProfileSheetState();
}

class _CreateProfileSheetState extends State<_CreateProfileSheet> {
  final _controller = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  DateTime? _birthday;
  bool _isValid = false;
  bool _useEmail = false;
  
  static const int _minNameLength = 2;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_validateInput);
    _emailController.addListener(_validateInput);
    _passwordController.addListener(_validateInput);
  }

  @override
  void dispose() {
    _controller.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _validateInput() {
    bool valid = _controller.text.trim().length >= _minNameLength && _birthday != null;
    if (_useEmail) {
      valid = valid && _emailController.text.contains('@') && _passwordController.text.length >= 6;
    }
    if (valid != _isValid) {
      setState(() => _isValid = valid);
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
            colorScheme: ColorScheme.dark(
              primary: Theme.of(context).primaryColor,
              onPrimary: Colors.black,
              surface: const Color(0xFF1A1A1A),
              onSurface: Colors.white,
            ),
            dialogTheme: const DialogThemeData(
              backgroundColor: Color(0xFF121212),
            ),
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
        color: Color(0xFF1A1A1A),
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
              errorText: _controller.text.isNotEmpty && !_isValid && !_useEmail
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
          
          const SizedBox(height: 16),
          CheckboxListTile(
            title: const Text('Create account for cloud sync', style: TextStyle(color: Colors.white70, fontSize: 14)),
            value: _useEmail,
            activeColor: Colors.greenAccent,
            onChanged: (val) {
              setState(() {
                _useEmail = val ?? false;
                _validateInput();
              });
            },
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
          ),
          
          if (_useEmail) ...[
            TextField(
              controller: _emailController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Email Address',
                labelStyle: TextStyle(color: Colors.white54),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white30)),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _passwordController,
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Password (min 6 chars)',
                labelStyle: TextStyle(color: Colors.white54),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white30)),
              ),
            ),
          ],

          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _isValid ? () => Navigator.pop(context, {
              'name': _controller.text.trim(),
              'birthday': _birthday,
              'email': _useEmail ? _emailController.text.trim() : null,
              'password': _useEmail ? _passwordController.text.trimRight() : null,
            }) : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: const Color(0xFF121212),
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
