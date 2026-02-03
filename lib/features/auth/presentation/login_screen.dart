import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../injection_container.dart' as di;
import '../../profile/domain/profile_model.dart';
import '../../profile/data/profile_repository.dart';
import '../../auth/domain/auth_repository.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  List<UserProfile> profiles = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfiles();
  }

  Future<void> _loadProfiles() async {
    final allProfiles = await di.sl<ProfileRepository>().getAllProfiles();
    if (mounted) {
      setState(() {
        profiles = allProfiles;
        isLoading = false;
      });
    }
  }

  Future<void> _createNewProfile() async {
    String? name = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _CreateProfileSheet(),
    );

    if (name != null && name.isNotEmpty) {
      setState(() => isLoading = true);
      final profile = await di.sl<ProfileRepository>().createProfile(name);
      await di.sl<AuthRepository>().signIn(profile.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/forest_background.png'),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(Colors.black38, BlendMode.darken),
          ),
        ),
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
          onTap: () => di.sl<AuthRepository>().signIn(p.id),
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
  String value = '';

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
            autofocus: true,
            style: const TextStyle(color: Colors.white),
            cursorColor: Colors.greenAccent,
            decoration: InputDecoration(
              labelText: 'Hunter Name',
              labelStyle: const TextStyle(color: Colors.white70),
              enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.3))),
              focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.greenAccent)),
            ),
            onChanged: (v) => value = v,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, value),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF81C784),
              foregroundColor: const Color(0xFF0F1E12),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('START HUNTING'),
          ),
        ],
      ),
    );
  }
}
