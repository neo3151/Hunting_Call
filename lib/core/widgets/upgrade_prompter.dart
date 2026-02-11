
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:hunting_calls_perfection/config/app_config.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/payment/data/payment_repository.dart';
import '../../providers/providers.dart';

class UpgradePrompter {
  static void show(BuildContext context, {String featureName = "This Feature"}) {
    showDialog(
      context: context,
      builder: (context) => Consumer(
        builder: (context, ref, child) {
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
                    "UNLOCK PRO",
                    style: GoogleFonts.oswald(
                      fontSize: 28, 
                      fontWeight: FontWeight.bold, 
                      color: Colors.white,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "$featureName is only available in the Full Version.",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.lato(color: Colors.white70, fontSize: 16),
                  ),
                  const SizedBox(height: 24),
                  _buildFeatureItem(Icons.star, "50+ Professional Calls"),
                  _buildFeatureItem(Icons.map, "Advanced Field Map"),
                  _buildFeatureItem(Icons.emoji_events, "Global Leaderboards"),
                  _buildFeatureItem(Icons.block, "No Ads"),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        // MOCK PURCHASE FLOW
                        final profile = ref.read(profileNotifierProvider).profile;
                        if (profile == null) return;
                        
                        // Show loading or just await
                        // For better UX, we could use a stateful widget / dedicated dialog,
                        // but for now let's just create a quick loading effect if possible,
                        // or just await.
                        
                        final scaffold = ScaffoldMessenger.of(context);
                        final navigator = Navigator.of(context);
                        
                        try {
                          // Remove invisible processing snackbar
                          // scaffold.showSnackBar(...) 
                          
                          final success = await ref.read(paymentRepositoryProvider).purchasePremium(profile.id);
                          
                          if (success) {
                            // 1. Reload profile first (State Update)
                            await ref.read(profileNotifierProvider.notifier).loadProfile(profile.id);
                            
                            if (context.mounted) {
                               // 2. Close Dialog (Make UI visible)
                               navigator.pop(); 
                               
                               // 3. Show Success SnackBar (on the underlying screen)
                               scaffold.showSnackBar(const SnackBar(
                                 content: Text("✅ Purchase Successful! Pro features unlocked."),
                                 backgroundColor: Colors.green,
                                 duration: Duration(seconds: 2),
                               ));
                            }
                          } else {
                             if (context.mounted) {
                               // For error, we can keep dialog open or close it. 
                               // Let's typically keep it open so they can retry?
                               // But if SnackBar is hidden, we must close or use dialog content.
                               // For now, let's close and show error.
                               navigator.pop();
                               scaffold.showSnackBar(const SnackBar(
                                 content: Text("❌ Purchase failed. Please try again."),
                                 backgroundColor: Colors.red,
                               ));
                             }
                          }
                        } catch (e) {
                           debugPrint("Purchase error: $e");
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFD700),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        "GET FULL VERSION", 
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
                    child: Text("MAYBE LATER", style: GoogleFonts.lato(color: Colors.white38)),
                  ),
                ],
              ),
            ),
          );
        }
      ),
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
