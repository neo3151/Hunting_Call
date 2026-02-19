import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/widgets/background_wrapper.dart';
import '../../recording/presentation/recorder_page.dart';
import '../../daily_challenge/data/daily_challenge_service.dart';
import '../../daily_challenge/presentation/daily_challenge_screen.dart';
import '../../settings/presentation/settings_screen.dart';
import 'controllers/home_controller.dart';
import 'widgets/home_header.dart';
import 'widgets/daily_challenge_card.dart';
import 'widgets/recent_activity_card.dart';

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
      ref.read(homeNotifierProvider.notifier).loadProfile(widget.userId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final homeState = ref.watch(homeNotifierProvider);
    final activeUserId = homeState.activeUserId.isEmpty
        ? widget.userId
        : homeState.activeUserId;

    // Initial load — no profile, no error, not loading
    if (homeState.profile == null &&
        homeState.error == null &&
        !homeState.isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFFFF8C00)),
        ),
      );
    }

    return Scaffold(
      body: BackgroundWrapper(
        child: SafeArea(
          child: homeState.isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.white))
              : homeState.error != null
                  ? _buildErrorState(homeState.error!)
                  : Column(
                      children: [
                        HomeHeader(
                          userName: homeState.userName,
                          isCloudMode: homeState.isCloudMode,
                          onSignOut: () => ref
                              .read(homeNotifierProvider.notifier)
                              .signOut(),
                          onSettings: () => Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) => const SettingsScreen()),
                          ),
                        ),
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 8),
                                _buildDailyChallenge(context, activeUserId),
                                const SizedBox(height: 24),
                                _buildActionGrid(context, activeUserId),
                                const SizedBox(height: 32),
                                if (homeState.mostRecentActivity != null) ...[
                                  Text('RECENT HUNTS',
                                      style: GoogleFonts.oswald(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white70)),
                                  const SizedBox(height: 16),
                                  RecentActivityCard(
                                      historyItem:
                                          homeState.mostRecentActivity!),
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

  // ─── Private Helpers ────────────────────────────────────────────────────

  Widget _buildErrorState(String errorMessage) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.cloud_off_outlined,
              color: Colors.orangeAccent, size: 64),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Column(
              children: [
                Text(
                  "Couldn't load your profile",
                  style: GoogleFonts.oswald(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  errorMessage,
                  style:
                      const TextStyle(color: Colors.white54, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => ref
                .read(homeNotifierProvider.notifier)
                .loadProfile(widget.userId),
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF8C00),
              foregroundColor: const Color(0xFF121212),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content:
                      Text('Contact support at: BenchmarkAppsLLC@gmail.com'),
                  backgroundColor: Color(0xFFFF8C00),
                ),
              );
            },
            child: Text(
              'Contact Support',
              style:
                  GoogleFonts.lato(color: Colors.white38, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyChallenge(BuildContext context, String activeUserId) {
    final challengeCall = DailyChallengeService.getDailyChallengeStatic();
    return DailyChallengeCard(
      challengeCall: challengeCall,
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
            builder: (_) => DailyChallengeScreen(userId: activeUserId)),
      ),
    );
  }

  Widget _buildActionGrid(BuildContext context, String activeUserId) {
    return Row(
      children: [
        // Quick Practice card
        Expanded(
          child: _buildQuickActionCard(
            icon: Icons.mic,
            iconColor: const Color(0xFFFF8C00),
            title: 'Quick\nPractice',
            subtitle: 'Start a session now',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (_) => RecorderPage(userId: activeUserId)),
            ),
          ),
        ),
        const SizedBox(width: 16),
        // Daily Challenge card
        Expanded(
          child: _buildQuickActionCard(
            icon: Icons.emoji_events,
            iconColor: const Color(0xFFFF8C00),
            title: 'Daily\nChallenge',
            subtitle: 'Compete for top scores',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (_) => DailyChallengeScreen(userId: activeUserId)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A).withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: iconColor.withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Icon(icon, color: iconColor, size: 28),
                ),
                const SizedBox(height: 14),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.oswald(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.lato(
                    fontSize: 11,
                    color: Colors.white54,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
