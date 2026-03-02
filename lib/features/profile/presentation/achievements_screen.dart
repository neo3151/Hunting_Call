import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:outcall/core/theme/app_colors.dart';
import 'package:outcall/core/widgets/staggered_fade_slide.dart';
import 'package:outcall/features/profile/domain/achievement_service.dart';
import 'package:outcall/features/profile/presentation/controllers/profile_controller.dart';
import 'package:outcall/features/profile/domain/entities/user_profile.dart';

/// Full-screen achievements gallery showing all 30 achievements with earned/locked status.
class AchievementsScreen extends ConsumerWidget {
  const AchievementsScreen({super.key});

  // Achievement category definitions
  static const List<_AchievementCategory> _categories = [
    _AchievementCategory(
      title: 'MILESTONES',
      subtitle: 'Recording progression',
      icon: Icons.flag_rounded,
      color: Color(0xFF5FF7B6),
      achievementIds: ['first_call', 'getting_started', 'dedicated_hunter', 'marathon_hunter', 'centurion', 'legend'],
    ),
    _AchievementCategory(
      title: 'SCORE TIERS',
      subtitle: 'Skill milestones',
      icon: Icons.military_tech,
      color: Color(0xFFFFD700),
      achievementIds: ['bronze_hunter', 'silver_hunter', 'gold_hunter', 'master_caller', 'perfectionist'],
    ),
    _AchievementCategory(
      title: 'CONSISTENCY',
      subtitle: 'Prove your skill',
      icon: Icons.trending_up,
      color: Colors.orangeAccent,
      achievementIds: ['consistent_80', 'consistent_90', 'average_elite'],
    ),
    _AchievementCategory(
      title: 'DIVERSITY',
      subtitle: 'Explore different species',
      icon: Icons.pets,
      color: Color(0xFF64B5F6),
      achievementIds: ['explorer', 'diverse_picker', 'wildlife_expert', 'call_collector'],
    ),
    _AchievementCategory(
      title: 'DAILY CHALLENGE',
      subtitle: 'Streaks & dedication',
      icon: Icons.local_fire_department,
      color: Colors.redAccent,
      achievementIds: ['challenger', 'streak_3', 'streak_7', 'streak_14', 'streak_30', 'challenge_veteran'],
    ),
    _AchievementCategory(
      title: 'MASTERY',
      subtitle: 'Deep expertise',
      icon: Icons.school,
      color: Color(0xFFCE93D8),
      achievementIds: ['specialist', 'master_of_one'],
    ),
    _AchievementCategory(
      title: 'HIDDEN',
      subtitle: 'Surprise achievements',
      icon: Icons.visibility_off,
      color: Colors.white54,
      achievementIds: ['night_owl', 'early_bird', 'comeback_kid', 'speed_demon', 'grinder'],
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = AppColors.of(context);
    final profile = ref.watch(profileNotifierProvider).profile;
    final earnedIds = profile != null
        ? AchievementService.getEarnedAchievements(profile).map((a) => a.id).toSet()
        : <String>{};
    final totalEarned = earnedIds.length;
    final totalAchievements = AchievementService.achievements.length;

    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        backgroundColor: palette.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: palette.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'ACHIEVEMENTS',
          style: GoogleFonts.oswald(
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
            fontSize: 16,
            color: palette.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
            children: [
              // Header — progress ring + earned count
              StaggeredFadeSlide(
                index: 0,
                child: _buildProgressHeader(palette, totalEarned, totalAchievements),
              ),
              const SizedBox(height: 28),
              // Category sections
              ..._categories.asMap().entries.map((entry) {
                final idx = entry.key;
                final category = entry.value;
                final categoryAchievements = category.achievementIds
                    .map((id) => AchievementService.achievements.firstWhere(
                          (a) => a.id == id,
                          orElse: () => Achievement(
                            id: id, name: id, description: '', icon: '❓',
                            isEarned: (_) => false,
                          ),
                        ))
                    .toList();
                final categoryEarned = categoryAchievements
                    .where((a) => earnedIds.contains(a.id))
                    .length;

                return StaggeredFadeSlide(
                  index: idx + 1,
                  child: _buildCategorySection(
                    context, palette, category, categoryAchievements,
                    earnedIds, categoryEarned, profile,
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressHeader(AppColorPalette palette, int earned, int total) {
    final progress = total > 0 ? earned / total : 0.0;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: palette.surfaceLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF5FF7B6).withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          // Progress ring
          SizedBox(
            width: 72,
            height: 72,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 72,
                  height: 72,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 6,
                    backgroundColor: palette.border,
                    color: const Color(0xFF5FF7B6),
                    strokeCap: StrokeCap.round,
                  ),
                ),
                Text(
                  '${(progress * 100).toInt()}%',
                  style: GoogleFonts.oswald(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: palette.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$earned / $total Unlocked',
                  style: GoogleFonts.oswald(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: palette.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  earned == 0
                      ? 'Start recording to earn achievements!'
                      : earned == total
                          ? 'You\'ve earned every achievement. Legend.'
                          : '${total - earned} more to unlock',
                  style: GoogleFonts.lato(
                    fontSize: 13,
                    color: palette.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySection(
    BuildContext context,
    AppColorPalette palette,
    _AchievementCategory category,
    List<Achievement> achievements,
    Set<String> earnedIds,
    int categoryEarned,
    UserProfile? profile,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category header
          Row(
            children: [
              Icon(category.icon, color: category.color, size: 18),
              const SizedBox(width: 8),
              Text(
                category.title,
                style: GoogleFonts.oswald(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                  color: category.color,
                ),
              ),
              const Spacer(),
              Text(
                '$categoryEarned/${achievements.length}',
                style: GoogleFonts.oswald(
                  fontSize: 12,
                  color: palette.textSubtle,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            category.subtitle,
            style: GoogleFonts.lato(fontSize: 11, color: palette.textSubtle),
          ),
          const SizedBox(height: 12),
          // Achievement tiles
          ...achievements.map((achievement) {
            final isEarned = earnedIds.contains(achievement.id);
            return _buildAchievementTile(palette, achievement, isEarned, category.color);
          }),
        ],
      ),
    );
  }

  Widget _buildAchievementTile(
    AppColorPalette palette,
    Achievement achievement,
    bool isEarned,
    Color categoryColor,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Semantics(
        label: '${achievement.name}: ${achievement.description}. ${isEarned ? "Earned" : "Locked"}',
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isEarned
                ? categoryColor.withValues(alpha: 0.08)
                : palette.surfaceLight,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isEarned
                  ? categoryColor.withValues(alpha: 0.3)
                  : palette.border,
            ),
          ),
          child: Row(
            children: [
              // Icon
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isEarned
                      ? categoryColor.withValues(alpha: 0.15)
                      : palette.border.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    isEarned ? achievement.icon : '🔒',
                    style: TextStyle(
                      fontSize: isEarned ? 22 : 18,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              // Name + description
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      achievement.name,
                      style: GoogleFonts.oswald(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: isEarned
                            ? palette.textPrimary
                            : palette.textSubtle,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      achievement.description,
                      style: GoogleFonts.lato(
                        fontSize: 11,
                        color: isEarned
                            ? palette.textSecondary
                            : palette.textSubtle.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              // Check or lock icon
              if (isEarned)
                Icon(Icons.check_circle, color: categoryColor, size: 22)
              else
                Icon(Icons.lock_outline, color: palette.textSubtle.withValues(alpha: 0.4), size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _AchievementCategory {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final List<String> achievementIds;

  const _AchievementCategory({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.achievementIds,
  });
}
