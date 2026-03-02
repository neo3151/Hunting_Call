import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:outcall/features/rating/domain/rating_model.dart';
import 'package:outcall/features/rating/domain/personality_feedback_service.dart';

/// Overall proficiency ring widget with animated count-up.
class OverallProficiency extends StatelessWidget {
  final dynamic score;

  const OverallProficiency({super.key, required this.score});

  double _toSafe(dynamic val) {
    if (val == null) return 0.0;
    if (val is num) return val.isFinite ? val.toDouble() : 0.0;
    return double.tryParse(val.toString()) ?? 0.0;
  }

  @override
  Widget build(BuildContext context) {
    final double s = _toSafe(score).clamp(0, 100);

    // Tier-based glow color
    final Color tierColor;
    if (s >= 90) {
      tierColor = const Color(0xFFFFD700); // Gold
    } else if (s >= 75) {
      tierColor = const Color(0xFF5FF7B6); // Green
    } else if (s >= 50) {
      tierColor = Colors.orangeAccent;
    } else {
      tierColor = Colors.redAccent;
    }

    return Semantics(
      label: 'Overall proficiency: ${s.toInt()} percent',
      child: TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 1200),
        curve: Curves.easeOutCubic,
        tween: Tween(begin: 0.0, end: s),
        builder: (context, animatedScore, _) {
          return Column(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  // Glow effect
                  Container(
                    width: 190,
                    height: 190,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: tierColor.withValues(alpha: 0.15 * (animatedScore / 100)),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 180,
                    height: 180,
                    child: CircularProgressIndicator(
                      value: animatedScore / 100,
                      strokeWidth: 10,
                      color: tierColor,
                      backgroundColor: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  Text(
                    '${animatedScore.toInt()}%',
                    style: GoogleFonts.oswald(
                      fontSize: 64,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'OVERALL PROFICIENCY',
                style: GoogleFonts.oswald(
                  fontSize: 11,
                  letterSpacing: 1.5,
                  color: Colors.white60,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// AI text feedback card.
class AIFeedbackCard extends StatelessWidget {
  final String feedback;

  const AIFeedbackCard({super.key, required this.feedback});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'AI Feedback: $feedback',
      child: Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.auto_awesome, color: Color(0xFF5FF7B6), size: 14),
              const SizedBox(width: 8),
              Text('AI FEEDBACK', style: GoogleFonts.oswald(fontSize: 11, letterSpacing: 1.5, color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          Text(feedback, textAlign: TextAlign.center, style: GoogleFonts.lato(fontSize: 14, color: Colors.white.withValues(alpha: 0.9), height: 1.5)),
        ],
      ),
      ),
    );
  }
}

/// "Reality Check" personality feedback card with animated entrance.
class PersonalityFeedbackCard extends StatelessWidget {
  final dynamic score;

  const PersonalityFeedbackCard({super.key, required this.score});

  double _toSafe(dynamic val) {
    if (val == null) return 0.0;
    if (val is num) return val.isFinite ? val.toDouble() : 0.0;
    return double.tryParse(val.toString()) ?? 0.0;
  }

  @override
  Widget build(BuildContext context) {
    final double s = _toSafe(score).clamp(0, 100);
    final String personalityMessage = PersonalityFeedbackService.getFeedback(s);

    final Color borderColor;
    if (s >= 85) {
      borderColor = const Color(0xFFFFD700);
    } else if (s >= 65) {
      borderColor = const Color(0xFF5FF7B6);
    } else if (s >= 50) {
      borderColor = Colors.orangeAccent;
    } else {
      borderColor = Colors.redAccent;
    }

    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 800),
      curve: Curves.elasticOut,
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, scale, child) {
        return Transform.scale(
          scale: 0.8 + (0.2 * scale),
          child: Opacity(
            opacity: scale.clamp(0.0, 1.0),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor.withValues(alpha: 0.5), width: 2),
                boxShadow: [BoxShadow(color: borderColor.withValues(alpha: 0.2 * scale), blurRadius: 15, spreadRadius: 2)],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.bolt, color: borderColor, size: 16),
                      const SizedBox(width: 8),
                      Text('REALITY CHECK', style: GoogleFonts.oswald(fontSize: 11, letterSpacing: 1.5, color: borderColor, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(personalityMessage, textAlign: TextAlign.center, style: GoogleFonts.lato(fontSize: 14, color: Colors.white.withValues(alpha: 0.95), height: 1.5, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Pro Breakdown: 4-column metric cards (Pitch, Timbre, Rhythm, Air).
class ProBreakdown extends StatelessWidget {
  final RatingResult result;

  const ProBreakdown({super.key, required this.result});

  double _toSafe(dynamic val) {
    if (val == null) return 0.0;
    if (val is num) return val.isFinite ? val.toDouble() : 0.0;
    return double.tryParse(val.toString()) ?? 0.0;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(width: 3, height: 14, decoration: const BoxDecoration(color: Color(0xFF5FF7B6), borderRadius: BorderRadius.all(Radius.circular(2)))),
            const SizedBox(width: 8),
            Text('PRO BREAKDOWN', style: GoogleFonts.oswald(fontSize: 12, letterSpacing: 1.5, color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildProMetricCard(context, 'PITCH', result.metrics['score_pitch'] ?? 0, Icons.music_note),
            _buildProMetricCard(context, 'TIMBRE', result.metrics['score_timbre'] ?? 0, Icons.flare),
            _buildProMetricCard(context, 'RHYTHM', result.metrics['score_rhythm'] ?? 0, Icons.speed),
            _buildProMetricCard(context, 'AIR', result.metrics['score_duration'] ?? 0, Icons.air),
          ],
        ),
      ],
    );
  }

  Widget _buildProMetricCard(BuildContext context, String label, dynamic score, IconData icon) {
    final double s = _toSafe(score).clamp(0, 100);
    final Color color = s >= 80 ? const Color(0xFF5FF7B6) : (s >= 50 ? Colors.orangeAccent : Colors.redAccent);

    return Semantics(
      label: '$label: ${s.toInt()} percent',
      child: Container(
      width: (MediaQuery.of(context).size.width - 60) / 4,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(height: 8),
          Text(label, style: GoogleFonts.oswald(fontSize: 9, color: Colors.white60, letterSpacing: 1)),
          const SizedBox(height: 4),
          Text('${s.toInt()}%', style: GoogleFonts.oswald(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
        ],
      ),
      ),
    );
  }
}

/// Primary flaw callout card — shows the weakest metric area.
class PrimaryFlawCard extends StatelessWidget {
  final RatingResult result;

  const PrimaryFlawCard({super.key, required this.result});

  double _toSafe(dynamic val) {
    if (val == null) return 0.0;
    if (val is num) return val.isFinite ? val.toDouble() : 0.0;
    return double.tryParse(val.toString()) ?? 0.0;
  }

  @override
  Widget build(BuildContext context) {
    final scores = {
      'pitch': _toSafe(result.metrics['score_pitch']),
      'timbre': _toSafe(result.metrics['score_timbre']),
      'rhythm': _toSafe(result.metrics['score_rhythm']),
      'duration': _toSafe(result.metrics['score_duration']),
    };

    final worst = scores.entries.reduce((a, b) => a.value < b.value ? a : b);
    if (worst.value >= 85) return const SizedBox.shrink();

    String flawTitle = '';
    String flawDesc = '';

    switch (worst.key) {
      case 'pitch':
        flawTitle = 'PITCH DEVIATION';
        flawDesc = "You're missing the target frequency. Practice your vocal control.";
        break;
      case 'timbre':
        flawTitle = 'TONAL INACCURACY';
        flawDesc = "The 'color' of your sound doesn't match the reference. Check your mouth position.";
        break;
      case 'rhythm':
        flawTitle = 'UNSTABLE RHYTHM';
        flawDesc = 'Your breathing or cadence is inconsistent. Focus on a steady flow.';
        break;
      case 'duration':
        flawTitle = 'AIR MANAGEMENT';
        flawDesc = 'Your calls are either too long or too short. Manage your breath better.';
        break;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.redAccent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.redAccent, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('PRIMARY FLAW: $flawTitle', style: GoogleFonts.oswald(fontSize: 12, color: Colors.redAccent, fontWeight: FontWeight.bold, letterSpacing: 1)),
                const SizedBox(height: 4),
                Text(flawDesc, style: GoogleFonts.lato(fontSize: 11, color: Colors.white70)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
