import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:outcall/core/theme/app_colors.dart';

/// Glassmorphic card displaying the daily challenge animal, metrics, and start button.
class ChallengeCard extends StatelessWidget {
  final dynamic challengeCall;
  final VoidCallback onStart;
  final int todayReps;
  final int currentStreak;

  const ChallengeCard({
    super.key,
    required this.challengeCall,
    required this.onStart,
    this.todayReps = 0,
    this.currentStreak = 0,
  });

  @override
  Widget build(BuildContext context) {
    final isComplete = todayReps >= 3;
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.of(context).cardOverlay,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.of(context).border),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.08),
                Colors.white.withValues(alpha: 0.03),
              ],
            ),
          ),
          child: Column(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFF5FF7B6).withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: const Color(0xFF5FF7B6).withValues(alpha: 0.4)),
                ),
                child: Icon(
                    isComplete ? Icons.check_rounded : Icons.record_voice_over,
                    color: const Color(0xFF5FF7B6),
                    size: 40),
              ),
              const SizedBox(height: 24),
              Text(
                challengeCall.animalName,
                style: GoogleFonts.oswald(
                  color: AppColors.of(context).textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                challengeCall.callType,
                style: GoogleFonts.lato(color: AppColors.of(context).textSecondary, fontSize: 14),
              ),
              if (currentStreak > 0) ...[
                const SizedBox(height: 8),
                Text(
                  '🔥 $currentStreak day streak',
                  style: GoogleFonts.lato(
                    color: Colors.orangeAccent,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
              const SizedBox(height: 32),
              _buildMetricStats(context),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isComplete ? null : onStart,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isComplete
                        ? AppColors.of(context).surfaceLight
                        : const Color(0xFF5FF7B6),
                    foregroundColor: Colors.black87,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    isComplete ? 'CHALLENGE COMPLETE ✓' : 'START CHALLENGE',
                    style: GoogleFonts.oswald(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricStats(BuildContext context) {
    final repsColor = todayReps >= 3
        ? const Color(0xFF5FF7B6)
        : AppColors.of(context).textSecondary;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildStatItem(context,
            'DIFFICULTY', challengeCall.difficulty.toUpperCase(), Colors.orangeAccent),
        _buildStatItem(context, 'REPS', '$todayReps/3', repsColor),
        _buildStatItem(context, 'REWARD', '+500 XP', const Color(0xFF5FF7B6)),
      ],
    );
  }

  Widget _buildStatItem(BuildContext context, String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.lato(
              color: AppColors.of(context).textSubtle, fontSize: 10, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.oswald(
              color: color, fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
