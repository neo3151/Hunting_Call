import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../injection_container.dart' as di;
import '../../profile/domain/profile_model.dart';
import '../../profile/data/profile_repository.dart';
import '../../auth/domain/auth_repository.dart';
import '../../recording/presentation/recorder_page.dart';
import '../../profile/presentation/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  final String userId;
  const HomeScreen({super.key, required this.userId});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String userName = "Hunter";
  UserProfile? _profile;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final profile = await di.sl<ProfileRepository>().getProfile(widget.userId);
    if (mounted) {
      setState(() {
        _profile = profile;
        userName = profile.name;
      });
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
            colorFilter: ColorFilter.mode(Colors.black45, BlendMode.darken),
          ),
        ),
        child: SafeArea(
        child: Column(
          children: [
             // Header
             _buildHeader(context),
             
             // Content
             Expanded(
               child: SingleChildScrollView(
                 padding: const EdgeInsets.all(24),
                 child: Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 3,
                            child: SizedBox(
                              height: 220,
                              child: _buildActionCard(
                                context,
                                title: "PRACTICE\nCALL",
                                icon: Icons.mic_external_on,
                                color: const Color(0xFFC5E1A5),
                                onTap: () => Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => RecorderPage(userId: widget.userId)),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 2,
                            child: Column(
                              children: [
                                SizedBox(
                                  height: 102,
                                  child: _buildActionCard(
                                    context,
                                    title: "PROFILE",
                                    icon: Icons.person_outline,
                                    color: const Color(0xFFD7CCC8),
                                    onTap: () => Navigator.of(context).push(
                                      MaterialPageRoute(builder: (_) => ProfileScreen(userId: widget.userId)),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                SizedBox(
                                  height: 102,
                                  child: _buildActionCard(
                                    context,
                                    title: "LIBRARY",
                                    icon: Icons.library_music_outlined,
                                    color: const Color(0xFFCFD8DC),
                                    onTap: () {}, // TODO
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      
                      if (_profile != null && _profile!.history.isNotEmpty) ...[
                        Text("RECENT HUNTS", style: GoogleFonts.oswald(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white70)),
                        const SizedBox(height: 16),
                        _buildRecentActivityCard(_profile!.history.first),
                      ],
                   ],
                 ),
               ),
             ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 60, 24, 40),
          decoration: BoxDecoration(
            color: const Color(0xFF1B3B24).withValues(alpha: 0.4),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("WELCOME BACK,",
                        style: GoogleFonts.oswald(
                            color: Colors.white70,
                            fontSize: 28,
                            fontWeight: FontWeight.w300,
                            letterSpacing: 1.0)),
                    Text(userName.toUpperCase(),
                        style: GoogleFonts.oswald(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            height: 1.1)),
                  ],
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  onPressed: () => di.sl<AuthRepository>().signOut(),
                  icon: const Icon(Icons.logout, color: Colors.white70),
                  tooltip: "Sign Out",
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionCard(BuildContext context,
      {required String title,
      required IconData icon,
      required Color color,
      required VoidCallback onTap}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CircleAvatar(
                  backgroundColor: color.withValues(alpha: 0.2),
                  foregroundColor: Colors.white,
                  child: Icon(icon),
                ),
                Text(title,
                    style: GoogleFonts.lato(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecentActivityCard(dynamic historyItem) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  historyItem.result.score.toStringAsFixed(0),
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orangeAccent, fontSize: 18),
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(historyItem.animalId.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  const Text("Last Session", style: TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
              const Spacer(),
              const Icon(Icons.chevron_right, color: Colors.white54),
            ],
          ),
        ),
      ),
    );
  }
}
