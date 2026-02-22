import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hunting_calls_perfection/features/leaderboard/data/mock_leaderboard_data.dart';

/// Compact leaderboard preview showing top 3 daily leaders.
class LeaderboardPreview extends StatelessWidget {
  const LeaderboardPreview({super.key});

  @override
  Widget build(BuildContext context) {
    final leaders = LeaderboardService.getDailyLeaders();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'DAILY LEADERS',
          style: GoogleFonts.oswald(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 16),
        ...leaders.take(3).map((entry) =>
            _buildLeaderItem(entry.rank, entry.username, '${entry.score.toInt()}%')),
      ],
    );
  }

  Widget _buildLeaderItem(int rank, String name, String score) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Text(
            '#$rank',
            style: GoogleFonts.oswald(
                color: Colors.white24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 16),
          Text(
            name,
            style: GoogleFonts.lato(color: Colors.white70, fontSize: 14),
          ),
          const Spacer(),
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
