import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:outcall/core/theme/app_colors.dart';
import 'package:outcall/core/widgets/staggered_fade_slide.dart';
import 'package:outcall/features/profile/presentation/controllers/profile_controller.dart';
import 'package:outcall/features/profile/domain/entities/user_profile.dart';
import 'package:outcall/l10n/app_localizations.dart';

/// Practice history dashboard with stats, per-animal breakdown, and score trend.
class HistoryDashboardScreen extends ConsumerWidget {
  const HistoryDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = AppColors.of(context);
    final profile = ref.watch(profileNotifierProvider).profile;

    if (profile == null) {
      return Scaffold(
        backgroundColor: palette.background,
        appBar: _buildAppBar(context, palette),
        body: Center(
          child: Text('No profile data', style: GoogleFonts.lato(color: palette.textSecondary)),
        ),
      );
    }

    final history = profile.history;
    if (history.isEmpty) {
      return Scaffold(
        backgroundColor: palette.background,
        appBar: _buildAppBar(context, palette),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.bar_chart_rounded, size: 64, color: palette.textSubtle),
              const SizedBox(height: 16),
              Text(S.of(context).noRecordingsYet,
                  style: GoogleFonts.oswald(fontSize: 20, color: palette.textPrimary, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(S.of(context).startFirstHunt,
                  style: GoogleFonts.lato(color: palette.textSecondary, fontSize: 14)),
            ],
          ),
        ),
      );
    }

    // Compute stats
    final totalSessions = history.length;
    final avgScore = history.map((h) => h.result.score).reduce((a, b) => a + b) / totalSessions;
    final bestScore = history.map((h) => h.result.score).reduce((a, b) => a > b ? a : b);

    // Per-animal breakdown
    final animalMap = <String, List<HistoryItem>>{};
    for (final h in history) {
      animalMap.putIfAbsent(h.animalId, () => []).add(h);
    }
    final animalStats = animalMap.entries.toList()
      ..sort((a, b) => b.value.length.compareTo(a.value.length));

    // Recent 10 scores for trend
    final recentScores = history.reversed.take(10).toList().reversed.toList();

    return Scaffold(
      backgroundColor: palette.background,
      appBar: _buildAppBar(context, palette),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              // Summary cards
              StaggeredFadeSlide(
                index: 0,
                child: _buildSummaryRow(context, palette, totalSessions, avgScore, bestScore),
              ),
              const SizedBox(height: 32),

              // Score trend
              StaggeredFadeSlide(
                index: 1,
                child: _buildScoreTrend(context, palette, recentScores),
              ),
              const SizedBox(height: 32),

              // Streak info
              StaggeredFadeSlide(
                index: 2,
                child: _buildStreakCard(context, palette, profile),
              ),
              const SizedBox(height: 32),

              // Per-animal breakdown
              StaggeredFadeSlide(
                index: 3,
                child: _buildSectionHeader(palette, S.of(context).animalBreakdown),
              ),
              const SizedBox(height: 12),
              ...animalStats.asMap().entries.map((entry) {
                final idx = entry.key;
                final animalId = entry.value.key;
                final items = entry.value.value;
                final animalBest = items.map((h) => h.result.score).reduce((a, b) => a > b ? a : b);
                final animalAvg = items.map((h) => h.result.score).reduce((a, b) => a + b) / items.length;

                return StaggeredFadeSlide(
                  index: 4 + idx,
                  child: _buildAnimalCard(context, palette, animalId, items.length, animalBest, animalAvg),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, AppColorPalette palette) {
    return AppBar(
      backgroundColor: palette.background,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios_new, color: palette.textPrimary, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        'PRACTICE HISTORY',
        style: GoogleFonts.oswald(
          fontWeight: FontWeight.bold,
          letterSpacing: 2,
          fontSize: 16,
          color: palette.textPrimary,
        ),
      ),
      centerTitle: true,
    );
  }

  Widget _buildSummaryRow(BuildContext context, AppColorPalette palette, int total, double avg, double best) {
    return Row(
      children: [
        Expanded(child: _buildStatCard(palette, S.of(context).totalSessions, '$total', Icons.mic, const Color(0xFF5FF7B6))),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard(palette, S.of(context).averageScore, '${avg.toInt()}%', Icons.speed, Colors.orangeAccent)),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard(palette, S.of(context).bestScore, '${best.toInt()}%', Icons.emoji_events, const Color(0xFFFFD700))),
      ],
    );
  }

  Widget _buildStatCard(AppColorPalette palette, String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(value, style: GoogleFonts.oswald(fontSize: 22, fontWeight: FontWeight.bold, color: palette.textPrimary)),
          const SizedBox(height: 4),
          Text(label, style: GoogleFonts.lato(fontSize: 9, color: palette.textSubtle, fontWeight: FontWeight.bold, letterSpacing: 1)),
        ],
      ),
    );
  }

  Widget _buildScoreTrend(BuildContext context, AppColorPalette palette, List<HistoryItem> recent) {
    if (recent.length < 2) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: palette.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(palette, 'RECENT TREND'),
          const SizedBox(height: 16),
          SizedBox(
            height: 100,
            child: CustomPaint(
              size: const Size(double.infinity, 100),
              painter: _ScoreTrendPainter(
                scores: recent.map((h) => h.result.score).toList(),
                lineColor: const Color(0xFF5FF7B6),
                dotColor: palette.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${recent.length} sessions ago', style: GoogleFonts.lato(fontSize: 10, color: palette.textSubtle)),
              Text('Latest', style: GoogleFonts.lato(fontSize: 10, color: palette.textSubtle)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStreakCard(BuildContext context, AppColorPalette palette, UserProfile profile) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: palette.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orangeAccent.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Text('🔥', style: TextStyle(fontSize: 32)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(S.of(context).challengeStreakTitle,
                    style: GoogleFonts.oswald(fontSize: 16, fontWeight: FontWeight.bold, color: palette.textPrimary)),
                const SizedBox(height: 4),
                Text('${profile.currentStreak} day current  •  ${profile.longestStreak} day best',
                    style: GoogleFonts.lato(fontSize: 13, color: palette.textSecondary)),
              ],
            ),
          ),
          Text('${profile.dailyChallengesCompleted}',
              style: GoogleFonts.oswald(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.orangeAccent)),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(AppColorPalette palette, String title) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 14,
          decoration: const BoxDecoration(
            color: Color(0xFF5FF7B6),
            borderRadius: BorderRadius.all(Radius.circular(2)),
          ),
        ),
        const SizedBox(width: 8),
        Text(title, style: GoogleFonts.oswald(fontSize: 12, letterSpacing: 1.5, color: palette.textPrimary, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildAnimalCard(BuildContext context, AppColorPalette palette, String animalId, int count, double best, double avg) {
    // Format animal name from ID (e.g., "elk_bugle" -> "Elk Bugle")
    final name = animalId
        .split('_')
        .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');

    final Color tierColor;
    if (best >= 90) {
      tierColor = const Color(0xFFFFD700);
    } else if (best >= 75) {
      tierColor = const Color(0xFF5FF7B6);
    } else if (best >= 50) {
      tierColor = Colors.orangeAccent;
    } else {
      tierColor = Colors.redAccent;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: palette.surfaceLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: palette.border),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: tierColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text('${best.toInt()}', style: GoogleFonts.oswald(fontSize: 16, fontWeight: FontWeight.bold, color: tierColor)),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: GoogleFonts.oswald(fontSize: 15, fontWeight: FontWeight.bold, color: palette.textPrimary)),
                  Text('$count sessions  •  Avg ${avg.toInt()}%', style: GoogleFonts.lato(fontSize: 11, color: palette.textSubtle)),
                ],
              ),
            ),
            // Mini bar
            SizedBox(
              width: 60,
              height: 6,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: best / 100,
                  backgroundColor: palette.border,
                  color: tierColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Custom painter for the score trend mini-chart.
class _ScoreTrendPainter extends CustomPainter {
  final List<double> scores;
  final Color lineColor;
  final Color dotColor;

  _ScoreTrendPainter({required this.scores, required this.lineColor, required this.dotColor});

  @override
  void paint(Canvas canvas, Size size) {
    if (scores.length < 2) return;

    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final dotPaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.fill;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [lineColor.withValues(alpha: 0.3), lineColor.withValues(alpha: 0.0)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final minScore = scores.reduce((a, b) => a < b ? a : b) - 5;
    final maxScore = scores.reduce((a, b) => a > b ? a : b) + 5;
    final range = (maxScore - minScore).clamp(10.0, 100.0);

    final path = Path();
    final fillPath = Path();

    for (int i = 0; i < scores.length; i++) {
      final x = (i / (scores.length - 1)) * size.width;
      final y = size.height - ((scores[i] - minScore) / range) * size.height;

      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }

    // Close fill path
    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);

    // Draw dots
    for (int i = 0; i < scores.length; i++) {
      final x = (i / (scores.length - 1)) * size.width;
      final y = size.height - ((scores[i] - minScore) / range) * size.height;
      canvas.drawCircle(Offset(x, y), 3, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _ScoreTrendPainter old) => old.scores != scores;
}
