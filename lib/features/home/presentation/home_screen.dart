import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hunting_calls_perfection/core/widgets/background_wrapper.dart';
import 'package:hunting_calls_perfection/core/widgets/skeleton_loader.dart';
import 'package:hunting_calls_perfection/features/recording/presentation/recorder_page.dart';
import 'package:hunting_calls_perfection/features/daily_challenge/presentation/daily_challenge_screen.dart';
import 'package:hunting_calls_perfection/features/daily_challenge/presentation/controllers/daily_challenge_controller.dart';
import 'package:hunting_calls_perfection/features/settings/presentation/settings_screen.dart';
import 'package:hunting_calls_perfection/features/leaderboard/presentation/global_leaderboard_screen.dart';
import 'package:hunting_calls_perfection/core/services/remote_config/remote_config_service.dart';
import 'package:hunting_calls_perfection/core/widgets/offline_banner.dart';
import 'package:hunting_calls_perfection/features/home/presentation/controllers/home_controller.dart';
import 'package:hunting_calls_perfection/features/home/presentation/widgets/home_header.dart';
import 'package:hunting_calls_perfection/features/home/presentation/widgets/daily_challenge_card.dart';
import 'package:hunting_calls_perfection/features/home/presentation/widgets/recent_activity_card.dart';

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
      return Scaffold(
        body: BackgroundWrapper(
          child: SafeArea(
            child: const DashboardSkeleton(),
          ),
        ),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldExit = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFF1A1A1A),
            title: Text('Exit App?', style: GoogleFonts.oswald(color: Colors.white)),
            content: Text('Are you sure you want to leave the Hunt?', style: GoogleFonts.lato(color: Colors.white70)),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('CANCEL', style: TextStyle(color: Colors.white54)),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text('EXIT', style: TextStyle(color: Theme.of(context).primaryColor)),
              ),
            ],
          ),
        );
        if (shouldExit == true) {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        body: BackgroundWrapper(
          child: SafeArea(
            child: homeState.isLoading
                ? const DashboardSkeleton()
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
                          const OfflineBanner(),
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
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: const Color(0xFF121212),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content:
                      const Text('Contact support at: BenchmarkAppsLLC@gmail.com'),
                  backgroundColor: Theme.of(context).primaryColor,
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
    final challengeAsync = ref.watch(dailyChallengeProvider);

    return challengeAsync.when(
      loading: () => ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          height: 180,
          color: Colors.white.withValues(alpha: 0.1),
          child: const Center(
            child: CircularProgressIndicator(color: Colors.greenAccent),
          ),
        ),
      ),
      error: (_, __) => const SizedBox.shrink(), // Or an error banner if desired
      data: (challengeCall) {
        if (challengeCall == null) return const SizedBox.shrink();

        return DailyChallengeCard(
          challengeCall: challengeCall,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
                builder: (_) => DailyChallengeScreen(userId: activeUserId)),
          ),
        );
      },
    );
  }

  Widget _buildActionGrid(BuildContext context, String activeUserId) {
    return Column(
      children: [
        Row(
          children: [
            // Quick Practice card
            Expanded(
              child: _buildQuickActionCard(
                icon: Icons.mic,
                iconColor: Theme.of(context).primaryColor,
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
                iconColor: Theme.of(context).primaryColor,
                title: 'Daily\nChallenge',
                subtitle: 'Compete for top scores',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) => DailyChallengeScreen(userId: activeUserId)),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            // Global Leaderboard card (Feature Flagged)
            if (ref.watch(remoteConfigServiceProvider).isLeaderboardEnabled)
              Expanded(
                child: _buildQuickActionCard(
                  icon: Icons.public,
                  iconColor: const Color(0xFF3A86FF),
                  title: 'Global\nRankings',
                  subtitle: 'See top hunters',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => const GlobalLeaderboardScreen()),
                  ),
                ),
              )
            else
              Expanded(
                child: _buildQuickActionCard(
                  icon: Icons.public_off,
                  iconColor: Colors.grey,
                  title: 'Rankings\nOffline',
                  subtitle: 'Coming back soon',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Global Rankings is currently undergoing maintenance.'),
                        backgroundColor: Theme.of(context).primaryColor,
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(width: 16),
            const Expanded(child: SizedBox.shrink()), // Placeholder for symmetry
          ],
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
