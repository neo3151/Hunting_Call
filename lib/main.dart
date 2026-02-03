import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'injection_container.dart' as di;
import 'core/theme/theme_notifier.dart';
import 'features/auth/domain/auth_repository.dart';
import 'features/recording/presentation/recorder_page.dart';
import 'features/profile/presentation/profile_screen.dart';
import 'features/profile/data/profile_repository.dart';
import 'features/profile/domain/profile_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await di.init();
  runApp(const HuntingCallsApp());
}

class HuntingCallsApp extends StatelessWidget {
  const HuntingCallsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ThemeNotifier(),
      child: Consumer<ThemeNotifier>(
        builder: (context, themeNotifier, child) {
          return MaterialApp(
            title: 'Hunting Calls Perfection',
            theme: themeNotifier.currentTheme,
            home: const RecorderPage(userId: 'test_user'),
            // home: const RatingScreen(audioPath: 'dummy_path.wav', animalId: 'Elk', userId: 'test_user'),
            builder: (context, child) {
               // Global Overlay for Theme Switcher could go here, 
               // but FloatingActionButton is requested on screens.
               return child!;
            },
          );
        },
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  String? userId;

  @override
  void initState() {
    super.initState();
    di.sl<AuthRepository>().onAuthStateChanged.listen((user) {
      setState(() {
        userId = user;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (userId == null) {
      return const LoginScreen();
    }
    return HomeScreen(userId: userId!);
  }
}

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
      builder: (context) => _CreateProfileSheet(),
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
                    // Logo / Hero Section
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
                    
                    // Profile List
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
                      // Quick Actions Grid
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
                      
                      // Recent Activity Preview
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
    // Assuming check logic, reusing simple display
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
                  Text("Last Session", style: const TextStyle(color: Colors.white70, fontSize: 12)),
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

