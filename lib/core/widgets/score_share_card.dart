import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:typed_data';
import 'package:outcall/l10n/app_localizations.dart';

/// Generates a shareable score card image and shares it via system share sheet.
class ScoreShareCard extends StatelessWidget {
  final double score;
  final String animalName;
  final String feedback;
  final GlobalKey _repaintKey = GlobalKey();

  ScoreShareCard({
    super.key,
    required this.score,
    required this.animalName,
    this.feedback = '',
  });

  Future<void> shareScore(BuildContext context) async {
    try {
      final boundary = _repaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final bytes = byteData.buffer.asUint8List();
      
      await Share.shareXFiles(
        [XFile.fromData(bytes, mimeType: 'image/png', name: 'outcall_score.png')],
        text: S.of(context).scoreShareText(score.toInt(), animalName),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not share: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color tierColor;
    if (score >= 90) {
      tierColor = const Color(0xFFFFD700);
    } else if (score >= 75) {
      tierColor = const Color(0xFF5FF7B6);
    } else if (score >= 50) {
      tierColor = Colors.orangeAccent;
    } else {
      tierColor = Colors.redAccent;
    }

    return RepaintBoundary(
      key: _repaintKey,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0D1B2A), Color(0xFF1B2838)],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: tierColor.withValues(alpha: 0.4), width: 2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('OUTCALL', style: GoogleFonts.oswald(color: const Color(0xFF5FF7B6), fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 2)),
                Text('🎯', style: const TextStyle(fontSize: 16)),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              '${score.toInt()}%',
              style: GoogleFonts.oswald(
                fontSize: 56,
                fontWeight: FontWeight.bold,
                color: tierColor,
              ),
            ),
            Text(
              animalName.toUpperCase(),
              style: GoogleFonts.oswald(
                fontSize: 14,
                color: Colors.white70,
                letterSpacing: 2,
              ),
            ),
            if (feedback.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                '"$feedback"',
                textAlign: TextAlign.center,
                style: GoogleFonts.lato(
                  fontSize: 11,
                  color: Colors.white54,
                  fontStyle: FontStyle.italic,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 16),
            Text(
              'huntingcall.app',
              style: GoogleFonts.lato(fontSize: 10, color: Colors.white24),
            ),
          ],
        ),
      ),
    );
  }
}
