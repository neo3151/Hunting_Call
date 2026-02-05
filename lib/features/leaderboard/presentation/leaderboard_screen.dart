import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../leaderboard/data/leaderboard_service.dart';
import '../../leaderboard/domain/leaderboard_entry.dart';

class LeaderboardScreen extends StatelessWidget {
  final String animalId;
  final String animalName;

  const LeaderboardScreen({
    super.key,
    required this.animalId,
    required this.animalName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B5E20),
        title: Text(
          "$animalName EXPERTS",
          style: GoogleFonts.oswald(fontWeight: FontWeight.bold, letterSpacing: 1.5),
        ),
      ),
      body: StreamBuilder<List<LeaderboardEntry>>(
        stream: GetIt.I<LeaderboardService>().getTopScores(animalId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF81C784)));
          }

          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}", style: const TextStyle(color: Colors.white70)));
          }

          final scores = snapshot.data ?? [];

          if (scores.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.emoji_events_outlined, color: Colors.white24, size: 64),
                  const SizedBox(height: 16),
                  Text(
                    "No experts yet.",
                    style: GoogleFonts.oswald(fontSize: 20, color: Colors.white54),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Be the first to score high!",
                    style: TextStyle(color: Colors.white38),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: scores.length,
            separatorBuilder: (context, index) => const Divider(color: Colors.white10),
            itemBuilder: (context, index) {
              final entry = scores[index];
              final isTop3 = index < 3;
              
              return ListTile(
                leading: _buildRankBadge(index + 1),
                title: Text(
                  entry.userName,
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                ),
                subtitle: Text(
                  DateFormat.yMMMd().format(entry.timestamp),
                  style: const TextStyle(color: Colors.white38, fontSize: 12),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      entry.score.toStringAsFixed(1),
                      style: GoogleFonts.oswald(
                        fontSize: 20, 
                        color: isTop3 ? const Color(0xFFFFD700) : const Color(0xFF81C784),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text("%", style: TextStyle(color: Colors.white30, fontSize: 12)),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildRankBadge(int rank) {
    Color bgColor;
    Color textColor = Colors.white;

    switch (rank) {
      case 1:
        bgColor = const Color(0xFFFFD700); // Gold
        textColor = Colors.black;
        break;
      case 2:
        bgColor = const Color(0xFFC0C0C0); // Silver
        textColor = Colors.black;
        break;
      case 3:
        bgColor = const Color(0xFFCD7F32); // Bronze
        break;
      default:
        bgColor = Colors.white.withValues(alpha: 0.1);
    }

    return Container(
      width: 32,
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
      ),
      child: Text(
        "#$rank",
        style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
      ),
    );
  }
}
