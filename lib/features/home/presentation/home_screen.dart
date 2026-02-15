import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/widgets/background_wrapper.dart';
import '../../recording/presentation/recorder_page.dart';
import '../../profile/presentation/profile_screen.dart';
import '../../library/presentation/library_screen.dart';
import '../../daily_challenge/data/daily_challenge_service.dart';
import '../../daily_challenge/presentation/daily_challenge_screen.dart';
import '../../hunting_log/presentation/hunting_log_screen.dart';
import '../../settings/presentation/settings_screen.dart';
import '../../weather/presentation/weather_screen.dart';
import 'controllers/home_controller.dart';
import 'widgets/home_header.dart';
import 'widgets/action_card.dart';
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
          child: CircularProgressIndicator(color: Color(0xFF81C784)),
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
                                  Text("RECENT HUNTS",
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
              backgroundColor: const Color(0xFF81C784),
              foregroundColor: const Color(0xFF0F1E12),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content:
                      Text('Contact support at: support@huntingcalls.app'),
                  backgroundColor: Color(0xFF81C784),
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: SizedBox(
            height: 220,
            child: ActionCard(
              title: "PRACTICE\nCALL",
              icon: Icons.mic_external_on,
              color: const Color(0xFFC5E1A5),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (_) => RecorderPage(userId: activeUserId)),
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
                child: ActionCard(
                  title: "PROFILE",
                  icon: Icons.person_outline,
                  color: const Color(0xFFD7CCC8),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) =>
                            ProfileScreen(userId: activeUserId)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 102,
                child: ActionCard(
                  title: "LIBRARY",
                  icon: Icons.library_music_outlined,
                  color: const Color(0xFFCFD8DC),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) =>
                            LibraryScreen(userId: activeUserId)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 102,
                child: ActionCard(
                  title: "LOG",
                  icon: Icons.history_edu,
                  color: const Color(0xFFBCAAA4),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => const HuntingLogScreen()),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 102,
                child: ActionCard(
                  title: "WEATHER",
                  icon: Icons.wb_sunny_outlined,
                  color: const Color(0xFFFFF9C4),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => const WeatherScreen()),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
