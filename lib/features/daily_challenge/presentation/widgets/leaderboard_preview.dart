import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:outcall/core/theme/app_colors.dart';
import 'package:outcall/features/leaderboard/domain/leaderboard_entry.dart'
    as lb;
import 'package:outcall/di_providers.dart';

/// Compact leaderboard preview showing top 3 daily leaders.
/// Uses real Firestore data via the leaderboard service provider.
class LeaderboardPreview extends ConsumerWidget {
  final String animalId;

  const LeaderboardPreview({super.key, required this.animalId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = AppColors.of(context);
    final leaderboardService = ref.watch(leaderboardServiceProvider);

    return StreamBuilder<List<lb.LeaderboardEntry>>(
      stream: leaderboardService?.getTopScores(animalId) ??
          Stream.value(<lb.LeaderboardEntry>[]),
      builder: (context, snapshot) {
        final leaders = snapshot.data ?? [];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'DAILY LEADERS',
              style: GoogleFonts.oswald(
                color: palette.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 16),
            if (leaders.isEmpty)
              Text(
                'No scores yet — be the first!',
                style: GoogleFonts.lato(
                  color: palette.textTertiary,
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                ),
              )
            else
              ...leaders.take(3).toList().asMap().entries.map((entry) {
                final rank = entry.key + 1;
                final leader = entry.value;
                return _buildLeaderItem(
                  context,
                  rank,
                  leader.userName,
                  '${leader.score.toInt()}%',
                );
              }),
          ],
        );
      },
    );
  }

  Widget _buildLeaderItem(
      BuildContext context, int rank, String name, String score) {
    final palette = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Text(
            '#$rank',
            style: GoogleFonts.oswald(
                color: palette.textSubtle, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              name,
              style:
                  GoogleFonts.lato(color: palette.textSecondary, fontSize: 14),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            score,
            style: GoogleFonts.oswald(
              color: const Color(0xFF5FF7B6),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
