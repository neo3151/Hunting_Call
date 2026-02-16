import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Glassmorphic card displaying the daily challenge animal, metrics, and start button.
class ChallengeCard extends StatelessWidget {
  final dynamic challengeCall;
  final VoidCallback onStart;

  const ChallengeCard({
    super.key,
    required this.challengeCall,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.1),
                Colors.white.withValues(alpha: 0.05),
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
                child: const Icon(Icons.record_voice_over,
                    color: Color(0xFF5FF7B6), size: 40),
              ),
              const SizedBox(height: 24),
              Text(
                challengeCall.animalName,
                style: GoogleFonts.oswald(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                challengeCall.callType,
                style: GoogleFonts.lato(color: Colors.white60, fontSize: 14),
              ),
              const SizedBox(height: 32),
              _buildMetricStats(),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onStart,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5FF7B6),
                    foregroundColor: Colors.black87,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    'START CHALLENGE',
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

  Widget _buildMetricStats() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildStatItem(
            'DIFFICULTY', challengeCall.difficulty.toUpperCase(), Colors.orangeAccent),
        _buildStatItem('REPS', '0/3', Colors.white70),
        _buildStatItem('REWARD', '+500 XP', const Color(0xFF5FF7B6)),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.lato(
              color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold),
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
