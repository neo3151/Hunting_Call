import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/daily_challenge_service.dart';
import '../../recording/presentation/recorder_page.dart';
import '../../leaderboard/data/mock_leaderboard_data.dart';
import 'package:intl/intl.dart';

class DailyChallengeScreen extends StatelessWidget {
  final String userId;
  const DailyChallengeScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    final challengeCall = DailyChallengeService.getDailyChallenge();

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "DAILY CHALLENGE",
          style: GoogleFonts.oswald(
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // Background
          Positioned.fill(
            child: Image.asset(
              challengeCall.imageUrl,
              fit: BoxFit.cover,
              color: Colors.black87,
              colorBlendMode: BlendMode.darken,
            ),
          ),
          
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 32),
                  _buildChallengeCard(context, challengeCall),
                  const Spacer(),
                  _buildLeaderboardPreview(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final dateStr = DateFormat("MMMM d, yyyy").format(DateTime.now()).toUpperCase();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          dateStr,
          style: GoogleFonts.lato(
            color: Colors.white54,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "CALL OF THE DAY",
          style: GoogleFonts.oswald(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 32,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildChallengeCard(BuildContext context, dynamic challengeCall) {
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
                  border: Border.all(color: const Color(0xFF5FF7B6).withValues(alpha: 0.4)),
                ),
                child: const Icon(Icons.record_voice_over, color: Color(0xFF5FF7B6), size: 40),
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
              _buildMetricStats(challengeCall),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => RecorderPage(
                          userId: userId, 
                          preselectedAnimalId: challengeCall.id
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5FF7B6),
                    foregroundColor: Colors.black87,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    "START CHALLENGE",
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

  Widget _buildMetricStats(dynamic challengeCall) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildStatItem("DIFFICULTY", challengeCall.difficulty.toUpperCase(), Colors.orangeAccent),
        _buildStatItem("REPS", "0/3", Colors.white70),
        _buildStatItem("REWARD", "+500 XP", const Color(0xFF5FF7B6)),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.lato(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.oswald(color: color, fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildLeaderboardPreview() {
    final leaders = LeaderboardService.getDailyLeaders();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "DAILY LEADERS",
          style: GoogleFonts.oswald(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 16),
        ...leaders.take(3).map((entry) => _buildLeaderItem(entry.rank, entry.username, "${entry.score.toInt()}%")),
      ],
    );
  }

  Widget _buildLeaderItem(int rank, String name, String score) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Text(
            "#$rank",
            style: GoogleFonts.oswald(color: Colors.white24, fontWeight: FontWeight.bold),
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
