import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../providers/providers.dart';
import '../../profile/domain/profile_model.dart';
import '../../library/data/reference_database.dart';
import '../domain/achievement_service.dart';
import '../../../core/widgets/background_wrapper.dart';
import '../../progress_map/presentation/progress_map_screen.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  final String userId;
  const ProfileScreen({super.key, required this.userId});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    // Load profile on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(profileNotifierProvider.notifier).loadProfile(widget.userId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileNotifierProvider);
    final profile = profileState.profile;
    final isLoading = profileState.isLoading;

    return BackgroundWrapper(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text("HANDLER PROFILE", style: GoogleFonts.oswald(letterSpacing: 1.5, fontWeight: FontWeight.bold)),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.white))
            : profile == null
                ? const Center(child: Text("Profile not found.", style: TextStyle(color: Colors.white70)))
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        // Header Section
                        _buildProfileHeader(profile),
                        const SizedBox(height: 32),
                        
                        // Stats Row
                        Row(
                          children: [
                            Expanded(child: _buildGlassStatCard("TOTAL CALLS", profile.totalCalls.toString(), Icons.mic)),
                            const SizedBox(width: 16),
                            Expanded(child: _buildGlassStatCard("AVG ACCURACY", "${profile.averageScore.toStringAsFixed(1)}%", Icons.analytics)),
                            const SizedBox(width: 16),
                            Expanded(child: _buildGlassStatCard("DAILY STREAK", "${profile.currentStreak} 🔥", Icons.local_fire_department)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        // Map Button
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => ProgressMapScreen(userId: widget.userId)),
                              );
                            },
                            icon: const Icon(Icons.map_outlined, color: Colors.white70),
                            label: const Text("VIEW FIELD MAP"),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 32),
                        
                        // Achievements Section
                        if (profile.achievements.isNotEmpty) ...[
                          _buildSectionHeader("HONORS & BADGES"),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 100,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: profile.achievements.length,
                              itemBuilder: (context, index) {
                                final achievementId = profile.achievements[index];
                                final achievement = AchievementService.achievements.firstWhere(
                                  (a) => a.id == achievementId,
                                  orElse: () => Achievement(
                                    id: 'unknown',
                                    name: 'Unknown',
                                    description: '',
                                    icon: '❓',
                                    isEarned: (_) => false,
                                  ),
                                );
                                return _buildAchievementBadge(achievement);
                              },
                            ),
                          ),
                          const SizedBox(height: 32),
                        ],
                        
                        // History Section
                        _buildSectionHeader("RECENT ACTIVITY"),
                        const SizedBox(height: 16),
                        if (profile.history.isEmpty)
                           _buildEmptyHistory()
                        else
                           ListView.builder(
                             shrinkWrap: true,
                             physics: const NeverScrollableScrollPhysics(),
                             itemCount: profile.history.length,
                             itemBuilder: (context, index) {
                               final item = profile.history[index];
                               return _buildHistoryCard(item);
                             },
                           ),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildProfileHeader(UserProfile profile) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.green.withValues(alpha: 0.2),
                blurRadius: 20,
                spreadRadius: 5,
              )
            ],
          ),
          child: const CircleAvatar(
            radius: 50,
            backgroundColor: Color(0xFF1B3B24),
            child: Icon(Icons.person, size: 50, color: Colors.white70),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          profile.name.toUpperCase(),
          style: GoogleFonts.oswald(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.0),
        ),
        Text(
          "HANDLING SINCE ${DateFormat.yMMMd().format(profile.joinedDate).toUpperCase()}",
          style: GoogleFonts.lato(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: GoogleFonts.oswald(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orangeAccent.withValues(alpha: 0.8), letterSpacing: 1.5),
      ),
    );
  }

  Widget _buildGlassStatCard(String label, String value, IconData icon) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: Colors.white54, size: 20),
              const SizedBox(height: 12),
              Text(value, style: GoogleFonts.oswald(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
              Text(label, style: GoogleFonts.lato(fontSize: 10, color: Colors.white38, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAchievementBadge(Achievement achievement) {
    return Container(
      width: 80,
      margin: const EdgeInsets.only(right: 16),
      child: Column(
        children: [
          Container(
            height: 60,
            width: 60,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.orangeAccent.withValues(alpha: 0.3)),
            ),
            child: Text(achievement.icon, style: const TextStyle(fontSize: 30)),
          ),
          const SizedBox(height: 8),
          Text(
            achievement.name,
            style: GoogleFonts.lato(fontSize: 10, color: Colors.white70, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(HistoryItem item) {
    final call = ReferenceDatabase.getById(item.animalId);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _getScoreColor(item.result.score).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    item.result.score.toStringAsFixed(0),
                    style: TextStyle(color: _getScoreColor(item.result.score), fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(call.animalName.toUpperCase(), style: GoogleFonts.oswald(color: Colors.white, fontWeight: FontWeight.bold)),
                      Text(DateFormat.yMMMd().add_jm().format(item.timestamp).toUpperCase(), style: GoogleFonts.lato(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: Colors.white12),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyHistory() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          const Icon(Icons.mic_none, color: Colors.white10, size: 48),
          const SizedBox(height: 16),
          Text("NO HUNTS RECORDED YET", style: GoogleFonts.oswald(color: Colors.white24, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 80) return Colors.greenAccent;
    if (score >= 60) return Colors.orangeAccent;
    return Colors.redAccent;
  }
}
