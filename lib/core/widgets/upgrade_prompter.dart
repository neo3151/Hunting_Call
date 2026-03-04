import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:outcall/features/payment/presentation/paywall_screen.dart';

class UpgradePrompter {
  static void show(BuildContext context, {String featureName = 'This Feature'}) {
    showDialog(
      context: context,
      builder: (context) => Consumer(builder: (context, ref, child) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFFFD700), width: 2),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFFD700).withValues(alpha: 0.2),
                  blurRadius: 20,
                  spreadRadius: 5,
                )
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_open_rounded, color: Color(0xFFFFD700), size: 48),
                const SizedBox(height: 16),
                Text(
                  'UNLOCK PRO',
                  style: GoogleFonts.oswald(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '$featureName is only available in the Full Version.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.lato(color: Colors.white70, fontSize: 16),
                ),
                const SizedBox(height: 24),
                _buildFeatureItem(Icons.star, '50+ Professional Calls'),
                _buildFeatureItem(Icons.map, 'Advanced Field Map'),
                _buildFeatureItem(Icons.emoji_events, 'Global Leaderboards'),
                _buildFeatureItem(Icons.block, 'No Ads'),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context); // Close dialog
                      PaywallScreen.show(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFD700),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      'GET FULL VERSION',
                      style: GoogleFonts.oswald(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('MAYBE LATER', style: GoogleFonts.lato(color: Colors.white38)),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  static Widget _buildFeatureItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFFFD700), size: 18),
          const SizedBox(width: 12),
          Text(text, style: GoogleFonts.lato(color: Colors.white, fontSize: 15)),
        ],
      ),
    );
  }
}
