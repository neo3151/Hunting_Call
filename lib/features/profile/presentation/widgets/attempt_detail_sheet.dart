import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:outcall/core/theme/app_colors.dart';
import 'package:outcall/features/library/domain/providers.dart';
import 'package:outcall/features/profile/domain/entities/user_profile.dart';

/// Shows full stats for a single call attempt when tapped.
///
/// Displays: overall score, 4-metric breakdown, pitch accuracy,
/// feedback text, attempt number, and progress vs previous attempts.
class AttemptDetailSheet extends ConsumerWidget {
  final HistoryItem item;
  final List<HistoryItem> allHistory;

  const AttemptDetailSheet({
    super.key,
    required this.item,
    required this.allHistory,
  });

  /// Show this sheet as a modal bottom sheet.
  static void show(BuildContext context, HistoryItem item, List<HistoryItem> allHistory) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AttemptDetailSheet(item: item, allHistory: allHistory),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = AppColors.of(context);
    final result = item.result;

    // Resolve animal name
    final getCallUseCase = ref.read(getCallByIdUseCaseProvider);
    final callResult = getCallUseCase.execute(item.animalId);
    String animalName = item.animalId;
    String callType = '';
    double idealPitchHz = 0;
    callResult.fold(
      (_) {},
      (reference) {
        animalName = reference.animalName;
        callType = reference.callType;
        idealPitchHz = reference.idealPitchHz;
      },
    );

    // Compute progress for this animal
    final sameAnimal = allHistory.where((h) => h.animalId == item.animalId).toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    final attemptIndex = sameAnimal
        .indexWhere((h) => h.timestamp == item.timestamp && h.result.score == item.result.score);
    final attemptNumber = attemptIndex >= 0 ? attemptIndex + 1 : sameAnimal.length;

    // Previous attempts for progress comparison (up to 5 before this one)
    final previousAttempts = attemptIndex > 0
        ? sameAnimal.sublist((attemptIndex - 5).clamp(0, attemptIndex), attemptIndex)
        : <HistoryItem>[];

    // Score color
    final scoreColor = _scoreColor(result.score);

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.92,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: palette.background,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(top: BorderSide(color: scoreColor.withValues(alpha: 0.3), width: 2)),
        ),
        child: ListView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: palette.textSubtle.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header: Score ring + animal info
            _buildHeader(palette, animalName, callType, scoreColor, result.score, attemptNumber,
                sameAnimal.length),
            const SizedBox(height: 24),

            // Date & time
            _buildDateRow(palette),
            const SizedBox(height: 24),

            // Metric cards
            _buildMetricsGrid(palette, result.metrics),
            const SizedBox(height: 24),

            // Pitch accuracy
            if (idealPitchHz > 0) ...[
              _buildPitchCard(palette, result.pitchHz, idealPitchHz),
              const SizedBox(height: 24),
            ],

            // AI Feedback
            if (result.feedback.isNotEmpty) ...[
              _buildFeedbackCard(palette, result.feedback),
              const SizedBox(height: 24),
            ],

            // Progress comparison
            if (previousAttempts.isNotEmpty) ...[
              _buildProgressSection(palette, previousAttempts, result.score),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(AppColorPalette palette, String animalName, String callType, Color scoreColor,
      double score, int attempt, int total) {
    return Row(
      children: [
        // Score ring
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
                  value: score / 100,
                  strokeWidth: 5,
                  backgroundColor: scoreColor.withValues(alpha: 0.15),
                  color: scoreColor,
                ),
              ),
              Text(
                '${score.toInt()}',
                style: GoogleFonts.oswald(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: scoreColor,
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
                animalName,
                style: GoogleFonts.oswald(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: palette.textPrimary,
                ),
              ),
              if (callType.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    callType,
                    style: GoogleFonts.lato(fontSize: 14, color: palette.textSecondary),
                  ),
                ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: scoreColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Attempt $attempt of $total',
                  style: GoogleFonts.lato(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: scoreColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDateRow(AppColorPalette palette) {
    final dateStr = DateFormat('MMM d, yyyy').format(item.timestamp);
    final timeStr = DateFormat('h:mm a').format(item.timestamp);

    return Row(
      children: [
        Icon(Icons.calendar_today, size: 14, color: palette.textSubtle),
        const SizedBox(width: 6),
        Text(dateStr, style: GoogleFonts.lato(fontSize: 13, color: palette.textSecondary)),
        const SizedBox(width: 16),
        Icon(Icons.access_time, size: 14, color: palette.textSubtle),
        const SizedBox(width: 6),
        Text(timeStr, style: GoogleFonts.lato(fontSize: 13, color: palette.textSecondary)),
      ],
    );
  }

  Widget _buildMetricsGrid(AppColorPalette palette, Map<String, double> metrics) {
    final icons = {
      'pitch': Icons.music_note,
      'timbre': Icons.graphic_eq,
      'rhythm': Icons.timer,
      'air': Icons.air,
    };
    final colors = {
      'pitch': const Color(0xFF5FF7B6),
      'timbre': const Color(0xFF64B5F6),
      'rhythm': Colors.orangeAccent,
      'air': const Color(0xFFCE93D8),
    };
    final labels = {
      'pitch': 'Pitch',
      'timbre': 'Tone\nQuality',
      'rhythm': 'Rhythm',
      'air': 'Breath\nControl',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel(palette, 'METRICS BREAKDOWN'),
        const SizedBox(height: 12),
        Row(
          children: metrics.entries.map((entry) {
            final key = entry.key.toLowerCase();
            final color = colors[key] ?? const Color(0xFF5FF7B6);
            final icon = icons[key] ?? Icons.bar_chart;
            final label = labels[key] ?? entry.key;
            return Expanded(
              child: _buildMetricCard(palette, label, entry.value, icon, color),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildMetricCard(
      AppColorPalette palette, String label, double value, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: palette.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 6),
          Text(
            '${value.toInt()}',
            style: GoogleFonts.oswald(
                fontSize: 20, fontWeight: FontWeight.bold, color: palette.textPrimary),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.lato(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
                color: palette.textSubtle),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: value / 100,
              backgroundColor: palette.border,
              color: color,
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPitchCard(AppColorPalette palette, double userPitch, double idealPitch) {
    final diff = (userPitch - idealPitch).abs();
    final direction = userPitch > idealPitch ? 'high' : 'low';
    final isOnTarget = diff < 15;
    final pitchColor = isOnTarget ? const Color(0xFF5FF7B6) : Colors.orangeAccent;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: pitchColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.tune, color: pitchColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('PITCH ACCURACY',
                    style: GoogleFonts.oswald(
                        fontSize: 11,
                        letterSpacing: 1,
                        color: palette.textSubtle,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(
                  isOnTarget
                      ? '${userPitch.toInt()} Hz — right on target!'
                      : '${userPitch.toInt()} Hz — ${diff.toInt()} Hz too $direction',
                  style: GoogleFonts.lato(
                      fontSize: 14, color: palette.textPrimary, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          Text(
            'Target: ${idealPitch.toInt()} Hz',
            style: GoogleFonts.lato(fontSize: 11, color: palette.textSubtle),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackCard(AppColorPalette palette, String feedback) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionLabel(palette, 'FEEDBACK'),
          const SizedBox(height: 8),
          Text(
            feedback,
            style: GoogleFonts.lato(fontSize: 13, color: palette.textSecondary, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSection(
      AppColorPalette palette, List<HistoryItem> previous, double currentScore) {
    final scores = [...previous.map((h) => h.result.score), currentScore];
    final prevBest = previous.map((h) => h.result.score).reduce((a, b) => a > b ? a : b);
    final delta = currentScore - prevBest;

    String trendText;
    Color trendColor;
    IconData trendIcon;
    if (delta > 3) {
      trendText = '+${delta.toInt()}% from previous best';
      trendColor = const Color(0xFF5FF7B6);
      trendIcon = Icons.trending_up;
    } else if (delta < -3) {
      trendText = '${delta.toInt()}% from previous best';
      trendColor = Colors.redAccent;
      trendIcon = Icons.trending_down;
    } else {
      trendText = 'Consistent with previous attempts';
      trendColor = Colors.orangeAccent;
      trendIcon = Icons.trending_flat;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: trendColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionLabel(palette, 'PROGRESS'),
          const SizedBox(height: 12),

          // Trend badge
          Row(
            children: [
              Icon(trendIcon, color: trendColor, size: 18),
              const SizedBox(width: 8),
              Text(trendText,
                  style: GoogleFonts.lato(
                      fontSize: 13, color: trendColor, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 16),

          // Mini bar chart
          SizedBox(
            height: 60,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: scores.asMap().entries.map((entry) {
                final isLast = entry.key == scores.length - 1;
                final barColor = isLast ? trendColor : palette.textSubtle.withValues(alpha: 0.3);
                final height = (entry.value / 100) * 52;

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          '${entry.value.toInt()}',
                          style: GoogleFonts.oswald(
                            fontSize: 9,
                            color: isLast ? trendColor : palette.textSubtle,
                            fontWeight: isLast ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Container(
                          height: height,
                          decoration: BoxDecoration(
                            color: barColor,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Previous', style: GoogleFonts.lato(fontSize: 9, color: palette.textSubtle)),
              Text('This attempt',
                  style: GoogleFonts.lato(
                      fontSize: 9, color: palette.textSubtle, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(AppColorPalette palette, String title) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 12,
          decoration: BoxDecoration(
            color: const Color(0xFF5FF7B6),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(title,
            style: GoogleFonts.oswald(
                fontSize: 11,
                letterSpacing: 1.5,
                color: palette.textPrimary,
                fontWeight: FontWeight.bold)),
      ],
    );
  }

  Color _scoreColor(double score) {
    if (score >= 90) return const Color(0xFFFFD700);
    if (score >= 75) return const Color(0xFF5FF7B6);
    if (score >= 50) return Colors.orangeAccent;
    return Colors.redAccent;
  }
}
