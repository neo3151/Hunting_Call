import 'dart:io' show Platform, File, Process;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:outcall/features/rating/domain/rating_model.dart';
import 'package:outcall/features/profile/presentation/controllers/profile_controller.dart';
import 'package:outcall/features/library/domain/providers.dart';
import 'package:outcall/config/app_config.dart';
import 'package:outcall/core/widgets/upgrade_prompter.dart';
import 'package:outcall/features/leaderboard/presentation/leaderboard_screen.dart';
import 'package:outcall/l10n/app_localizations.dart';
import 'package:outcall/core/widgets/score_share_card.dart';
import 'package:outcall/core/theme/app_colors.dart';

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
        child: Text(S.of(context).goBack, style: GoogleFonts.oswald()),
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
                label: Text(S.of(context).tryAgain, style: GoogleFonts.oswald(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
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
                label: Text(S.of(context).saveShareRecording, style: GoogleFonts.oswald(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
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
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white70,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: Text(S.of(context).doneReturnToCamp, style: GoogleFonts.oswald(fontSize: 12, fontWeight: FontWeight.w500, letterSpacing: 1.5)),
              ),
            ),
            
            // Report a Problem
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: () => _showReportModal(context, animal.animalName, ref),
                icon: const Icon(Icons.flag_outlined, size: 14, color: Colors.white38),
                label: Text('REPORT SCORING ISSUE', style: GoogleFonts.oswald(fontSize: 11, color: Colors.white38, letterSpacing: 1.0)),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showReportModal(BuildContext context, String animalName, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext modalContext) {
        return _ReportIssueBottomSheet(
          animalId: animalId,
          animalName: animalName,
          result: result,
          userId: ref.read(profileNotifierProvider).profile?.id ?? 'guest',
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
          label: Text(S.of(context).viewGlobalRankings, style: GoogleFonts.oswald(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
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
        label: Text(S.of(context).globalRankingsLocked, style: GoogleFonts.oswald(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
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

    final score = result!.score;
    final scoreStr = score.toInt().toString();
    final tierLabel = _getTierLabel(score);
    
    // Build rich stats text
    final buffer = StringBuffer();
    buffer.writeln('🎯 OUTCALL — $animalName Call');
    buffer.writeln('━━━━━━━━━━━━━━━━━━');
    buffer.writeln('📊 Score: $scoreStr% ($tierLabel)');
    if (result!.pitchHz > 0) {
      buffer.writeln('🎵 Pitch: ${result!.pitchHz.toStringAsFixed(0)} Hz');
    }
    if (result!.metrics.isNotEmpty) {
      for (final entry in result!.metrics.entries) {
        final label = entry.key[0].toUpperCase() + entry.key.substring(1);
        buffer.writeln('   • $label: ${entry.value.toInt()}%');
      }
    }
    if (result!.feedback.isNotEmpty) {
      buffer.writeln('');
      buffer.writeln('💬 "${result!.feedback}"');
    }
    buffer.writeln('');
    buffer.writeln('Think you can beat me? 🦌');
    buffer.writeln('https://hunting-call-perfection.web.app');

    final text = buffer.toString();

    if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
      // ─── Desktop: Save audio to Downloads ──────────────────────────
      try {
        final downloadsDir = await getDownloadsDirectory();
        if (downloadsDir != null) {
          final ts = DateTime.now().millisecondsSinceEpoch;
          final audioFileName = 'outcall_recording_$ts.m4a';
          final audioDestPath = '${downloadsDir.path}/$audioFileName';
          await File(audioPath).copy(audioDestPath);

          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Saved to Downloads: $audioFileName'),
                backgroundColor: AppColors.success,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }

          if (Platform.isLinux) {
            await Process.run('xdg-open', [downloadsDir.path]);
          } else if (Platform.isWindows) {
            await Process.run('explorer.exe', ['/select,', audioDestPath]);
          } else if (Platform.isMacOS) {
            await Process.run('open', ['-R', audioDestPath]);
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
      // ─── Mobile: Share score card image + audio + stats ─────────────
      final files = <XFile>[XFile(audioPath)];

      // Try to capture branded score card as image
      try {
        final cardImage = await _captureScoreCard(
          context, score, animalName, result!.feedback,
          metrics: result!.metrics, pitchHz: result!.pitchHz,
        );
        if (cardImage != null) {
          final tempDir = await getTemporaryDirectory();
          final imgPath = '${tempDir.path}/outcall_score_${DateTime.now().millisecondsSinceEpoch}.png';
          await File(imgPath).writeAsBytes(cardImage);
          files.insert(0, XFile(imgPath));
        }
      } catch (_) {
        // If card capture fails, just share text + audio
      }

      await SharePlus.instance.share(ShareParams(
        files: files,
        text: text,
      ));
    }
  }

  /// Renders a ScoreShareCard off-screen and captures it as a PNG.
  Future<List<int>?> _captureScoreCard(
      BuildContext context, double score, String animalName, String feedback,
      {Map<String, double> metrics = const {}, double pitchHz = 0}) async {
    final card = ScoreShareCard(
      score: score, animalName: animalName, feedback: feedback,
      metrics: metrics, pitchHz: pitchHz,
    );
    final overlay = Overlay.of(context);

    // Place card off-screen to render it
    final entry = OverlayEntry(
      builder: (_) => Positioned(
        left: -500,
        top: -500,
        child: Material(color: Colors.transparent, child: card),
      ),
    );
    overlay.insert(entry);

    // Wait for the widget to render
    await Future.delayed(const Duration(milliseconds: 300));

    final bytes = await card.captureImage();
    entry.remove();
    return bytes;
  }

  String _getTierLabel(double score) {
    if (score >= 95) return 'MASTER';
    if (score >= 85) return 'EXPERT';
    if (score >= 70) return 'SKILLED';
    if (score >= 50) return 'LEARNING';
    return 'ROOKIE';
  }
}

class _ReportIssueBottomSheet extends StatefulWidget {
  final String animalId;
  final String animalName;
  final RatingResult? result;
  final String userId;

  const _ReportIssueBottomSheet({
    required this.animalId,
    required this.animalName,
    required this.result,
    required this.userId,
  });

  @override
  State<_ReportIssueBottomSheet> createState() => _ReportIssueBottomSheetState();
}

class _ReportIssueBottomSheetState extends State<_ReportIssueBottomSheet> {
  String? _selectedReason;
  bool _isSubmitting = false;
  final TextEditingController _detailsController = TextEditingController();

  final List<String> _reasons = [
    'Scored my voice, not my call',
    'Score seems way too low',
    'Score seems way too high',
    'Scored background noise',
    'App crashed or froze',
    'Other'
  ];

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  Future<void> _submitReport() async {
    if (_selectedReason == null) return;
    
    setState(() => _isSubmitting = true);
    
    try {
      await FirebaseFirestore.instance.collection('bug_reports').add({
        'timestamp': FieldValue.serverTimestamp(),
        'userId': widget.userId,
        'animalId': widget.animalId,
        'animalName': widget.animalName,
        'reason': _selectedReason,
        'additionalDetails': _detailsController.text.trim(),
        'score': widget.result?.score,
        'pitchHz': widget.result?.pitchHz,
        'status': 'open',
      });
      
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Report submitted. Thank you!', style: GoogleFonts.lato()),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting report. Try again.', style: GoogleFonts.lato()),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).padding.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.flag_outlined, color: Colors.orangeAccent),
              const SizedBox(width: 12),
              Text(
                'REPORT AN ISSUE',
                style: GoogleFonts.oswald(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'What went wrong with the scoring for this ${widget.animalName} call?',
            style: GoogleFonts.lato(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 24),
          ..._reasons.map((reason) {
            final isSelected = _selectedReason == reason;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: InkWell(
                onTap: () => setState(() => _selectedReason = reason),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.orangeAccent.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? Colors.orangeAccent : Colors.transparent,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                        color: isSelected ? Colors.orangeAccent : Colors.white38,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          reason,
                          style: GoogleFonts.lato(
                            color: isSelected ? Colors.white : Colors.white70,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
          
          // Optional Details Text Field
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: _selectedReason != null ? null : 0,
            margin: EdgeInsets.only(top: _selectedReason != null ? 8.0 : 0),
            child: _selectedReason != null
                ? TextField(
                    controller: _detailsController,
                    style: GoogleFonts.lato(color: Colors.white, fontSize: 14),
                    maxLines: 3,
                    minLines: 1,
                    textInputAction: TextInputAction.done,
                    decoration: InputDecoration(
                      hintText: _selectedReason == 'Other' 
                          ? 'Please describe the issue...' 
                          : 'Additional details (optional)',
                      hintStyle: GoogleFonts.lato(color: Colors.white38),
                      filled: true,
                      fillColor: Colors.black.withValues(alpha: 0.3),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.orangeAccent.withValues(alpha: 0.5)),
                      ),
                      contentPadding: const EdgeInsets.all(16),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _selectedReason == null || _isSubmitting ? null : _submitReport,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orangeAccent,
                foregroundColor: Colors.black,
                disabledBackgroundColor: Colors.white12,
                disabledForegroundColor: Colors.white38,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isSubmitting
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                  : Text(
                      'SUBMIT REPORT',
                      style: GoogleFonts.oswald(fontWeight: FontWeight.bold, letterSpacing: 1.5),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

