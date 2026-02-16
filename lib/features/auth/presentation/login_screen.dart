import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hunting_calls_perfection/di_providers.dart';
import 'controllers/auth_controller.dart';

import '../../../core/widgets/background_wrapper.dart';
import '../../profile/presentation/controllers/profile_controller.dart';
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

    if (name.isNotEmpty) {
      
      try {
        // 1. Sign in anonymously first
        await ref.read(authControllerProvider.notifier).signInAnonymously();
        
        // 2. Get the user ID from the repository
        // (Stream-based state may not have propagated yet, so query directly)
        
        final currentUser = await ref.read(authRepositoryProvider).currentUser;
        final safeUid = currentUser?.id;
        
        if (safeUid != null) {
          // 3. Create the profile with that UID
          await ref.read(profileNotifierProvider.notifier).createProfile(name, id: safeUid, birthday: birthday);
        } else {
          throw Exception('Could not retrieve user ID after sign-in.');
        }
      } catch (e) {
        if (mounted) {
          debugPrint('Profile creation failed: $e');
          String message = 'Authentication failed. Please check your internet connection.';
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

  Future<void> _signInWithEmail() async {
    final emailController = TextEditingController();
    
    final email = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1B3B24),
        title: const Text('Log In', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Enter the email address associated with your profile to sync progress.',
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
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, emailController.text.trim()),
            child: const Text('LOG IN', style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (email != null && email.isNotEmpty) {
      if (!mounted) return;
      
      try {
        final profileRepo = ref.read(profileRepositoryProvider);
        // debugPrint("🔍 Searching for profiles by email: $email");
        
        final profiles = await profileRepo.getProfilesByEmail(email);
        
        if (profiles.isNotEmpty) {
          UserProfile? selectedProfile;
          
          // Always ask user to confirm/pick, even if there's only one.
          // This ensures they know WHICH profile they are logging into.
          if (!mounted) return;
          selectedProfile = await showDialog<UserProfile>(
            context: context,
            builder: (context) => SimpleDialog(
              title: const Text('Select Profile', style: TextStyle(color: Colors.white)),
              backgroundColor: const Color(0xFF1B3B24),
              children: profiles.map((p) => SimpleDialogOption(
                onPressed: () => Navigator.pop(context, p),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white24),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      Text('Joined: ${DateFormat.yMMMd().format(p.joinedDate)}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                      Text('Calls: ${p.totalCalls}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                ),
              )).toList(),
            ),
          );
          
          if (selectedProfile != null) {
            // debugPrint("✅ Profile selected: ${selectedProfile.name} (${selectedProfile.id})");
            
            // Load profile to state FIRST, before signIn triggers AuthWrapper rebuild
            await ref.read(profileNotifierProvider.notifier).loadProfile(selectedProfile.id);
            
            // Now sign in (this fires the auth stream → AuthWrapper rebuilds,
            // but the profile is already loaded so AuthWrapper finds it)
            await ref.read(authControllerProvider.notifier).signIn(selectedProfile.id);
          }
          
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('No profile found with this email.'),
                backgroundColor: Colors.orange,
              )
            );
          }
        }
      } catch (e) {
        debugPrint('❌ Email login failed: $e');
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text('Login error: $e'), backgroundColor: Colors.red)
           );
        }
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    try {
      // debugPrint('🔐 Starting Google Sign-In via AuthController...');
      
      // AuthController now handles:
      // 1. Sign in with Google
      // 2. Ensure profile exists (Create if needed)
      await ref.read(authControllerProvider.notifier).signInWithGoogle();
      
      // Success is handled by AuthWrapper watching the state change
      // debugPrint('✅ Google Sign-In triggered successfully');
      
    } catch (e, stackTrace) {
      debugPrint('❌ Google Sign-In failed: $e');
      debugPrint('Stack trace: $stackTrace');
      
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
                              const Icon(Icons.forest_rounded, size: 80, color: Color(0xFF81C784)),
                              const SizedBox(height: 24),
                              Text(
                                'GOBBLE\nGURU',
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
                                  backgroundColor: const Color(0xFF81C784),
                                  foregroundColor: const Color(0xFF0F1E12),
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
            dialogTheme: const DialogThemeData(
              backgroundColor: Color(0xFF0F1E12),
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
