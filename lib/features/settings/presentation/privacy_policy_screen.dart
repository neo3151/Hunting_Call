import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          'PRIVACY POLICY',
          style: GoogleFonts.oswald(letterSpacing: 1.5, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(
              title: "1. Information Collection",
              content: "We collect basic profile information (name, birthday) to personalize your experience. "
                  "When you sign in with Google, we authenticate using your Google account but do not store your password. "
                  "Audio recordings are processed locally on your device for analysis, unless you explicitly choose to save or share them.",
            ),
            const SizedBox(height: 24),
            _buildSection(
              title: "2. Data Usage",
              content: "Your data is used to:\\n"
                  "• Track your progress and achievements\\n"
                  "• Provide personalized hunting call feedback\\n"
                  "• Calculate leaderboards (if participating)\\n"
                  "We do not sell your personal data to third parties.",
            ),
            const SizedBox(height: 24),
            _buildSection(
              title: "3. Audio Privacy",
              content: "Your hunting call recordings belong to you. Our advanced frequency analysis happens on-device. "
                  "Recordings are only uploaded if you use cloud sync features, and they are stored securely associated with your account.",
            ),
            const SizedBox(height: 24),
            _buildSection(
              title: "4. Account Deletion",
              content: "You can request full account deletion at any time from the settings menu. "
                  "This will permanently remove your profile, history, and any stored recordings.",
            ),
            const SizedBox(height: 48),
            Center(
              child: Text(
                "Last Updated: February 2026",
                style: GoogleFonts.lato(color: Colors.white38, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required String content}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.oswald(
            color: const Color(0xFF81C784),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: GoogleFonts.lato(
            color: Colors.white70,
            fontSize: 15,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}
