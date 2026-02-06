import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/widgets/background_wrapper.dart';
import '../../../providers/providers.dart';
import '../../profile/domain/profile_model.dart';

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
    String? name = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _CreateProfileSheet(),
    );

    if (name != null && name.isNotEmpty) {
      final authRepo = ref.read(authRepositoryProvider);
      
      try {
        // 1. Sign in anonymously first
        await authRepo.signInAnonymously();
        
        // 2. Get the UID
        final uid = authRepo.currentUserId;
        
        if (uid != null) {
          // 3. Create the profile with that UID
          await ref.read(profileNotifierProvider.notifier).createProfile(name, id: uid);
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

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileNotifierProvider);
    final profiles = profileState.allProfiles;
    final isLoading = profileState.isLoading;

    return Scaffold(
      body: BackgroundWrapper(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Spacer(),
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
                    const Spacer(),
                    Text(
                       "WHO IS HUNTING?",
                       style: GoogleFonts.lato(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    if (isLoading)
                      const Center(child: CircularProgressIndicator(color: Colors.white))
                    else if (profileState.error != null)
                      _buildErrorDisplay(profileState.error!)
                    else if (profiles.isEmpty)
                       _buildEmptyState()
                    else
                      Container(
                        constraints: const BoxConstraints(maxHeight: 300),
                        child: ListView.separated(
                          shrinkWrap: true,
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
                    const Spacer(),
                  ],
                ),
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
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: const Text(
        "No profiles found.\nCreate your first hunter profile to begin.",
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.white60),
      ),
    );
  }

  Widget _buildProfileCard(UserProfile p) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: InkWell(
          onTap: () => ref.read(authRepositoryProvider).signIn(p.id),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFF81C784).withValues(alpha: 0.2),
                  foregroundColor: Colors.white,
                  child: Text(p.name[0].toUpperCase()),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.name, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      Text(
                        "${p.totalCalls} calls • ${p.averageScore.toStringAsFixed(0)}% avg",
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.white54),
              ],
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
    final isValid = _controller.text.trim().length >= _minNameLength;
    if (isValid != _isValid) {
      setState(() => _isValid = isValid);
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
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _isValid ? () => Navigator.pop(context, _controller.text.trim()) : null,
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
