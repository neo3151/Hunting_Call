import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../auth/presentation/login_screen.dart';
import '../../../core/widgets/background_wrapper.dart';
import '../../auth/presentation/controllers/auth_controller.dart';
import '../../../providers/providers.dart'; // Keep for profileNotifierProvider if it's still there
import '../../profile/domain/profile_model.dart';
import '../../recording/presentation/recorder_page.dart';
import '../../profile/presentation/profile_screen.dart';
import '../../library/presentation/library_screen.dart';
import '../../daily_challenge/data/daily_challenge_service.dart';
import '../../daily_challenge/presentation/daily_challenge_screen.dart';
import '../../hunting_log/presentation/hunting_log_screen.dart';
import '../../weather/presentation/weather_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  final String userId;
  const HomeScreen({super.key, required this.userId});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Check if profile is already loaded (AuthWrapper pre-loads it)
      final currentProfile = ref.read(profileNotifierProvider).profile;
      if (currentProfile != null && currentProfile.id != 'guest') {
        debugPrint("HomeScreen: Profile already loaded: ${currentProfile.name}");
        // Refresh using the actual profile ID, not the Firebase UID
        ref.read(profileNotifierProvider.notifier).loadProfile(currentProfile.id);
      } else {
        // No profile loaded yet, try with widget.userId
        debugPrint("HomeScreen: No profile loaded, trying widget.userId: ${widget.userId}");
        ref.read(profileNotifierProvider.notifier).loadProfile(widget.userId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileNotifierProvider);
    final profile = profileState.profile;
    final isProfileLoading = profileState.isProfileLoading;
    final errorMessage = profileState.error;
    final userName = profile?.name ?? "Hunter";
    final activeUserId = profile?.id ?? widget.userId;
    
    // Show loading if profile is not yet loaded to prevent missing data
    if (profile == null && errorMessage == null && !isProfileLoading) {
       return const Scaffold(
         body: Center(
           child: CircularProgressIndicator(color: Color(0xFF81C784)),
         ),
       );
    }

    return Scaffold(
      body: BackgroundWrapper(
        child: SafeArea(
        child: isProfileLoading 
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : errorMessage != null
            ? _buildErrorState(errorMessage)
            : Column(
          children: [
             // Header
             _buildHeader(context, userName),
             
             // Content
             Expanded(
               child: SingleChildScrollView(
                 padding: const EdgeInsets.all(24),
                 child: Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                      const SizedBox(height: 8),
                      // Daily Challenge Card
                      _buildDailyChallengeCard(context, activeUserId),
                      const SizedBox(height: 24),
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
                                  MaterialPageRoute(builder: (_) => RecorderPage(userId: activeUserId)),
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
                                      MaterialPageRoute(builder: (_) => ProfileScreen(userId: activeUserId)),
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
                                    onTap: () => Navigator.of(context).push(
                                      MaterialPageRoute(builder: (_) => LibraryScreen(userId: activeUserId)),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                SizedBox(
                                  height: 102,
                                  child: _buildActionCard(
                                    context,
                                    title: "LOG",
                                    icon: Icons.history_edu,
                                    color: const Color(0xFFBCAAA4),
                                    onTap: () => Navigator.of(context).push(
                                      MaterialPageRoute(builder: (_) => const HuntingLogScreen()),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                SizedBox(
                                  height: 102,
                                  child: _buildActionCard(
                                    context,
                                    title: "WEATHER",
                                    icon: Icons.wb_sunny_outlined,
                                    color: const Color(0xFFFFF9C4),
                                    onTap: () => Navigator.of(context).push(
                                      MaterialPageRoute(builder: (_) => const WeatherScreen()),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      
                      if (profile != null && profile.history.isNotEmpty) ...[
                        Text("RECENT HUNTS", style: GoogleFonts.oswald(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white70)),
                        const SizedBox(height: 16),
                        _buildRecentActivityCard(profile.history.first),
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

  Widget _buildErrorState(String errorMessage) {
    bool isProfileNotFound = errorMessage.contains("NOT_FOUND") || 
                             errorMessage.contains("Document") && errorMessage.contains("not found");

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isProfileNotFound ? Icons.person_off_outlined : Icons.error_outline, 
            color: Colors.redAccent, 
            size: 64
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Text(
              isProfileNotFound 
                  ? "Profile not found. Please create or select a hunter profile." 
                  : errorMessage,
              style: const TextStyle(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              if (isProfileNotFound) {
                // Navigate back to login screen to create/select profile
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
                // Also reset auth state so AuthWrapper doesn't immediately put us back here
                ref.read(authControllerProvider.notifier).signOut();
              } else {
                ref.read(profileNotifierProvider.notifier).loadProfile(widget.userId);
              }
            },
            icon: Icon(isProfileNotFound ? Icons.person_add : Icons.refresh),
            label: Text(isProfileNotFound ? 'Create / Select Profile' : 'Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF81C784),
              foregroundColor: const Color(0xFF0F1E12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String userName) {
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
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: ref.watch(authRepositoryImplProvider).isMock 
                          ? Colors.amber.withValues(alpha: 0.2) 
                          : Colors.green.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: ref.watch(authRepositoryImplProvider).isMock 
                            ? Colors.amberAccent.withValues(alpha: 0.5) 
                            : Colors.greenAccent.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          ref.watch(authRepositoryImplProvider).isMock ? Icons.wifi_off : Icons.cloud_done,
                          size: 12,
                          color: ref.watch(authRepositoryImplProvider).isMock ? Colors.amberAccent : Colors.greenAccent,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          ref.watch(authRepositoryImplProvider).isMock ? "OFF-GRID" : "CLOUD",
                          style: GoogleFonts.lato(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: ref.watch(authRepositoryImplProvider).isMock ? Colors.amberAccent : Colors.greenAccent,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      onPressed: () => ref.read(authControllerProvider.notifier).signOut(),
                      icon: const Icon(Icons.logout, color: Colors.white70),
                      tooltip: "Sign Out",
                    ),
                  )
                ],
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
  
  Widget _buildDailyChallengeCard(BuildContext context, String activeUserId) {
    final challengeCall = DailyChallengeService.getDailyChallengeStatic();
    
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: Image.asset(
              challengeCall.imageUrl,
              fit: BoxFit.cover,
            ),
          ),
          // Gradient Overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Colors.black.withValues(alpha: 0.8),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          // Content
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                 Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => DailyChallengeScreen(userId: activeUserId)),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.orangeAccent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              "DAILY CHALLENGE", 
                              style: GoogleFonts.oswald(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black)
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            "MASTER THE\n${challengeCall.animalName.toUpperCase()}",
                            style: GoogleFonts.oswald(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.bolt, color: Colors.yellowAccent, size: 16),
                              const SizedBox(width: 4),
                              Text("+500 XP Bonus", style: GoogleFonts.lato(color: Colors.yellowAccent, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white30),
                      ),
                      child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 32),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivityCard(HistoryItem historyItem) {
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
