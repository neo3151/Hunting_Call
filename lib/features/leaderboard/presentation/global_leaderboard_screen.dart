import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:outcall/core/theme/app_colors.dart';
import 'package:outcall/core/widgets/background_wrapper.dart';
import 'package:outcall/core/widgets/skeleton_loader.dart';
import 'package:outcall/features/leaderboard/presentation/controllers/leaderboard_controller.dart';

/// Global Leaderboard showing top users across ALL animals.
class GlobalLeaderboardScreen extends ConsumerWidget {
  const GlobalLeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(globalLeaderboardProvider);
    final colors = AppColors.of(context);
    final primary = Theme.of(context).primaryColor;

    return Scaffold(
      body: BackgroundWrapper(
        child: SafeArea(
          child: Column(
            children: [
              // App bar
              Container(
                padding: const EdgeInsets.fromLTRB(8, 8, 16, 16),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back, color: colors.textPrimary),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'GLOBAL RANKINGS',
                      style: GoogleFonts.oswald(
                        color: colors.textPrimary,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const Spacer(),
                    const Icon(Icons.emoji_events, color: Color(0xFFFFD700), size: 28),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: usersAsync.when(
                  loading: () => const ListSkeleton(),
                  error: (e, _) => Center(
                    child: Text('Error: $e', style: TextStyle(color: colors.textSecondary)),
                  ),
                  data: (users) {
                    if (users.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.leaderboard_outlined, color: colors.border, size: 64),
                            const SizedBox(height: 16),
                            Text(
                              'No rankings yet.',
                              style: GoogleFonts.oswald(fontSize: 20, color: colors.textTertiary),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Complete calls to get ranked!',
                              style: TextStyle(color: colors.textSubtle),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: users.length,
                      itemBuilder: (context, index) {
                        final user = users[index];
                        final rank = index + 1;
                        final isTop3 = rank <= 3;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: isTop3
                                ? _podiumColor(rank).withValues(alpha: 0.1)
                                : colors.cardOverlay,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isTop3
                                  ? _podiumColor(rank).withValues(alpha: 0.3)
                                  : colors.border.withValues(alpha: 0.2),
                            ),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            leading: _buildRankBadge(rank, colors),
                            title: Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    user.name,
                                    style: GoogleFonts.lato(
                                      color: colors.textPrimary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (user.isAlphaTester) ...[
                                  const SizedBox(width: 4),
                                  const Icon(Icons.star, color: Colors.orangeAccent, size: 14),
                                ],
                              ],
                            ),
                            subtitle: Text(
                              '${user.totalCalls} calls • ${user.history.map((h) => h.animalId).toSet().length} species',
                              style: GoogleFonts.lato(color: colors.textSubtle, fontSize: 12),
                            ),
                            trailing: Text(
                              '${user.averageScore.toStringAsFixed(0)}%',
                              style: GoogleFonts.oswald(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: isTop3 ? _podiumColor(rank) : primary,
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _podiumColor(int rank) {
    switch (rank) {
      case 1: return const Color(0xFFFFD700); // Gold
      case 2: return const Color(0xFFC0C0C0); // Silver
      case 3: return const Color(0xFFCD7F32); // Bronze
      default: return Colors.white54;
    }
  }

  Widget _buildRankBadge(int rank, AppColorPalette colors) {
    final isPodium = rank <= 3;
    return Container(
      width: 36,
      height: 36,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isPodium ? _podiumColor(rank) : colors.border,
        shape: BoxShape.circle,
      ),
      child: Text(
        '#$rank',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: isPodium && rank <= 2 ? Colors.black : Colors.white,
          fontSize: 13,
        ),
      ),
    );
  }
}
