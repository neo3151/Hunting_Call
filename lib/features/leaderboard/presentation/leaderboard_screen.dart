import 'package:flutter/material.dart';
import 'package:outcall/core/theme/app_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:outcall/core/widgets/skeleton_loader.dart';
import 'package:outcall/features/leaderboard/presentation/controllers/leaderboard_controller.dart';
import 'package:outcall/features/leaderboard/presentation/global_leaderboard_screen.dart';

class LeaderboardScreen extends ConsumerWidget {
  final String animalId;
  final String animalName;

  const LeaderboardScreen({
    super.key,
    required this.animalId,
    required this.animalName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scoresAsync = ref.watch(leaderboardScoresProvider(animalId));

    return Scaffold(
      backgroundColor: AppColors.of(context).background,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B5E20),
        title: Text(
          '$animalName EXPERTS',
          style: GoogleFonts.oswald(fontWeight: FontWeight.bold, letterSpacing: 1.5),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.public, color: Colors.white70),
            tooltip: 'Global Rankings',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const GlobalLeaderboardScreen()),
            ),
          ),
        ],
      ),
      body: scoresAsync.when(
        loading: () => const ListSkeleton(),
        error: (error, stack) => Center(child: Text('Error: $error', style: TextStyle(color: AppColors.of(context).textSecondary))),
        data: (scores) {
          if (scores.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.emoji_events_outlined, color: AppColors.of(context).border, size: 64),
                  const SizedBox(height: 16),
                  Text(
                    'No experts yet.',
                    style: GoogleFonts.oswald(fontSize: 20, color: AppColors.of(context).textTertiary),
                  ),
                  const SizedBox(height: 8),
                   Text(
                    'Be the first to score high!',
                    style: TextStyle(color: AppColors.of(context).textSubtle),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: scores.length,
            separatorBuilder: (context, index) => Divider(color: AppColors.of(context).divider),
            itemBuilder: (context, index) {
              final entry = scores[index];
              final isTop3 = index < 3;
              
              return ListTile(
                leading: _buildRankBadge(context, index + 1),
                title: Row(
                  children: [
                    Flexible(
                      child: Text(
                        entry.userName,
                        style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.of(context).textPrimary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (entry.isAlphaTester) ...[
                      const SizedBox(width: 4),
                      const Icon(Icons.star, color: Colors.orangeAccent, size: 14),
                    ],
                  ],
                ),
                subtitle: Text(
                  DateFormat.yMMMd().format(entry.timestamp),
                  style: TextStyle(color: AppColors.of(context).textSubtle, fontSize: 12),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      entry.score.toStringAsFixed(1),
                      style: GoogleFonts.oswald(
                        fontSize: 20, 
                        color: isTop3 ? const Color(0xFFFFD700) : Theme.of(context).primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text('%', style: TextStyle(color: Colors.white30, fontSize: 12)),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildRankBadge(BuildContext context, int rank) {
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
        bgColor = AppColors.of(context).border;
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
        '#$rank',
        style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
      ),
    );
  }
}
