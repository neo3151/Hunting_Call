import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io' show Platform, File, Process;
import 'package:path_provider/path_provider.dart';
import 'package:outcall/features/rating/domain/rating_model.dart';
import 'package:outcall/features/profile/presentation/controllers/profile_controller.dart';
import 'package:outcall/features/library/domain/providers.dart';
import 'package:outcall/config/app_config.dart';
import 'package:outcall/core/widgets/upgrade_prompter.dart';
import 'package:outcall/features/leaderboard/presentation/leaderboard_screen.dart';

/// Action buttons at the bottom of the rating screen:
/// Try Again, Save/Share, Leaderboard, Done.
class RatingActionButtons extends ConsumerWidget {
  final RatingResult? result;
  final String audioPath;
  final String animalId;

  const RatingActionButtons({
    super.key,
    required this.result,
    required this.audioPath,
    required this.animalId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final getCallUseCase = ref.read(getCallByIdUseCaseProvider);
    final callResult = getCallUseCase.execute(animalId);

    return callResult.fold(
      (failure) => ElevatedButton(
        onPressed: () => Navigator.of(context).pop(),
        child: Text('GO BACK', style: GoogleFonts.oswald()),
      ),
      (animal) {
        final bool showLeaderboard = AppConfig.instance.allowLeaderboard ||
            (ref.watch(profileNotifierProvider).profile?.isPremium ?? false);

        return Column(
          children: [
            // Try Again
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.refresh_rounded),
                label: Text('TRY AGAIN', style: GoogleFonts.oswald(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5FF7B6),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Save / Share
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _handleShare(context, animal.animalName),
                icon: const Icon(Icons.share, color: Colors.white),
                label: Text('SAVE / SHARE RECORDING', style: GoogleFonts.oswald(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Leaderboard
            _buildLeaderboardButton(context, showLeaderboard, animal.animalName),
            const SizedBox(height: 16),

            // Done
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                },
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white70,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: Text('DONE & RETURN TO CAMP', style: GoogleFonts.oswald(fontSize: 12, fontWeight: FontWeight.w500, letterSpacing: 1.5)),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLeaderboardButton(BuildContext context, bool showLeaderboard, String animalName) {
    if (showLeaderboard) {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: () {
            Navigator.push(context, MaterialPageRoute(
              builder: (_) => LeaderboardScreen(animalId: animalId, animalName: animalName),
            ));
          },
          icon: Icon(Icons.emoji_events_outlined, color: Theme.of(context).primaryColor),
          label: Text('VIEW GLOBAL RANKINGS', style: GoogleFonts.oswald(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            side: BorderSide(color: Theme.of(context).primaryColor.withValues(alpha: 0.5)),
            padding: const EdgeInsets.symmetric(vertical: 20),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => UpgradePrompter.show(context, featureName: 'Global Leaderboards'),
        icon: const Icon(Icons.lock_outline, color: Colors.white38),
        label: Text('GLOBAL RANKINGS (LOCKED)', style: GoogleFonts.oswald(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white38,
          side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
          padding: const EdgeInsets.symmetric(vertical: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Future<void> _handleShare(BuildContext context, String animalName) async {
    if (result == null) return;

    final scoreStr = result!.score.toInt().toString();
    final text = 'I just scored $scoreStr% on the $animalName call in OUTCALL! Think you can beat me? 🦌🦆';

    if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
      try {
        final downloadsDir = await getDownloadsDirectory();
        if (downloadsDir != null) {
          final fileName = 'outcall_recording_${DateTime.now().millisecondsSinceEpoch}.m4a';
          final destPath = '${downloadsDir.path}/$fileName';
          await File(audioPath).copy(destPath);

          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Saved to Downloads: $fileName (Opening folder...)'),
                backgroundColor: const Color(0xFF5FF7B6),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }

          if (Platform.isLinux) {
            await Process.run('xdg-open', [downloadsDir.path]);
          } else if (Platform.isWindows) {
            await Process.run('explorer.exe', ['/select,', destPath]);
          } else if (Platform.isMacOS) {
            await Process.run('open', ['-R', destPath]);
          }
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error saving file: $e'), backgroundColor: Colors.redAccent),
          );
        }
      }
    } else {
      await Share.shareXFiles([XFile(audioPath)], text: text);
    }
  }
}
