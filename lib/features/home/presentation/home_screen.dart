import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:outcall/core/widgets/background_wrapper.dart';
import 'package:outcall/core/theme/app_colors.dart';
import 'package:outcall/core/widgets/skeleton_loader.dart';
import 'package:outcall/features/recording/presentation/recorder_page.dart';
import 'package:outcall/features/daily_challenge/presentation/daily_challenge_screen.dart';
import 'package:outcall/features/daily_challenge/presentation/controllers/daily_challenge_controller.dart';
import 'package:outcall/features/settings/presentation/settings_screen.dart';
import 'package:outcall/features/leaderboard/presentation/global_leaderboard_screen.dart';
import 'package:outcall/core/services/remote_config/remote_config_service.dart';
import 'package:outcall/core/widgets/offline_banner.dart';
import 'package:outcall/core/utils/friendly_errors.dart';
import 'package:outcall/features/home/presentation/controllers/home_controller.dart';
import 'package:outcall/features/home/presentation/widgets/home_header.dart';
import 'package:outcall/features/home/presentation/widgets/daily_challenge_card.dart';
import 'package:outcall/features/home/presentation/widgets/recent_activity_card.dart';

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

    return Scaffold(
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
                            child: Center(
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 600),
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
                                            color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.black54)),
                                    const SizedBox(height: 16),
                                    RecentActivityCard(
                                        historyItem:
                                            homeState.mostRecentActivity!),
                                  ],
                                ],
                              ),
                            ),
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
    final friendlyMessage = FriendlyErrorFormatter.format(errorMessage);
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
                    color: isDark ? Colors.white : Colors.black87,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  friendlyMessage,
                  style:
                      TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 12),
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
              foregroundColor: isDark ? const Color(0xFF121212) : Colors.white,
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
                  GoogleFonts.lato(color: AppColors.of(context).textSubtle, fontSize: 12),
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
          color: AppColors.of(context).cardOverlay,
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
    return Semantics(
      label: '$title. $subtitle',
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.of(context).surface.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.of(context).border),
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
                      color: AppColors.of(context).textPrimary,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.lato(
                      fontSize: 11,
                      color: AppColors.of(context).textTertiary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
