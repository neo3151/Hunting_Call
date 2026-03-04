import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:outcall/core/theme/app_colors.dart';

/// Generates a premium branded score card image and shares it.
/// Uses the gold/charcoal Outcall aesthetic.
class ScoreShareCard extends StatelessWidget {
  final double score;
  final String animalName;
  final String feedback;
  final Map<String, double> metrics;
  final double pitchHz;
  final GlobalKey _repaintKey = GlobalKey();

  ScoreShareCard({
    super.key,
    required this.score,
    required this.animalName,
    this.feedback = '',
    this.metrics = const {},
    this.pitchHz = 0,
  });

  /// Capture the card as a PNG image (Uint8List).
  Future<List<int>?> captureImage() async {
    try {
      final boundary = _repaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return null;

      return byteData.buffer.asUint8List();
    } catch (e) {
      return null;
    }
  }

  /// Capture and share the score card image.
  Future<void> shareScore(BuildContext context) async {
    final bytes = await captureImage();
    if (bytes == null) return;

    try {
      await SharePlus.instance.share(ShareParams(
        files: [XFile.fromData(
          bytes as dynamic,
          mimeType: 'image/png',
          name: 'outcall_score.png',
        )],
        text: _shareText,
      ));
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not share: $e')),
        );
      }
    }
  }

  String get _shareText =>
      'I just scored ${score.toInt()}% on the $animalName call in OUTCALL! 🎯🦌\n\n'
      'Think you can beat me? Download OUTCALL:\n'
      'https://hunting-call-perfection.web.app';

  String get _tierLabel {
    if (score >= 95) return 'MASTER';
    if (score >= 85) return 'EXPERT';
    if (score >= 70) return 'SKILLED';
    if (score >= 50) return 'LEARNING';
    return 'ROOKIE';
  }

  Color get _tierColor {
    if (score >= 90) return AppColors.accentGold;
    if (score >= 75) return const Color(0xFF5FF7B6);
    if (score >= 50) return Colors.orangeAccent;
    return Colors.redAccent;
  }

  @override
  Widget build(BuildContext context) {
    // Extract pro breakdown metrics
    final pitch = (metrics['score_pitch'] ?? 0).clamp(0, 100).toDouble();
    final timbre = (metrics['score_timbre'] ?? 0).clamp(0, 100).toDouble();
    final rhythm = (metrics['score_rhythm'] ?? 0).clamp(0, 100).toDouble();
    final air = (metrics['score_duration'] ?? 0).clamp(0, 100).toDouble();
    final hasMetrics = pitch > 0 || timbre > 0 || rhythm > 0 || air > 0;

    return RepaintBoundary(
      key: _repaintKey,
      child: Container(
        width: 340,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A1A1A), Color(0xFF0D0D0D)],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: _tierColor.withValues(alpha: 0.4),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: _tierColor.withValues(alpha: 0.15),
              blurRadius: 30,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ─── Header ─────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'OUTCALL',
                  style: GoogleFonts.oswald(
                    color: AppColors.accentGold,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 3,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _tierColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(50),
                    border: Border.all(color: _tierColor.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    _tierLabel,
                    style: GoogleFonts.oswald(
                      color: _tierColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ─── Score ──────────────────────────────────
            ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                colors: [
                  _tierColor,
                  _tierColor.withValues(alpha: 0.7),
                  _tierColor,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ).createShader(bounds),
              child: Text(
                '${score.toInt()}',
                style: GoogleFonts.oswald(
                  fontSize: 64,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  height: 1.0,
                ),
              ),
            ),
            Text(
              'ACCURACY',
              style: GoogleFonts.oswald(
                fontSize: 12,
                color: Colors.white38,
                letterSpacing: 4,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),

            // ─── Divider ────────────────────────────────
            Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    _tierColor.withValues(alpha: 0.4),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ─── Animal ─────────────────────────────────
            Text(
              animalName.toUpperCase(),
              style: GoogleFonts.oswald(
                fontSize: 18,
                color: Colors.white,
                fontWeight: FontWeight.w600,
                letterSpacing: 2,
              ),
            ),

            // ─── Pitch Readout ──────────────────────────
            if (pitchHz > 0) ...[
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.music_note, size: 12, color: Colors.white38),
                  const SizedBox(width: 4),
                  Text(
                    '${pitchHz.toStringAsFixed(0)} Hz',
                    style: GoogleFonts.lato(
                      fontSize: 12,
                      color: Colors.white38,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],

            // ─── Pro Breakdown Metrics ──────────────────
            if (hasMetrics) ...[
              const SizedBox(height: 20),
              Container(
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      Colors.white.withValues(alpha: 0.1),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildMetricColumn('PITCH', pitch),
                  _buildMetricColumn('TIMBRE', timbre),
                  _buildMetricColumn('RHYTHM', rhythm),
                  _buildMetricColumn('AIR', air),
                ],
              ),
            ],

            // ─── Feedback ───────────────────────────────
            if (feedback.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      Colors.white.withValues(alpha: 0.1),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                '"$feedback"',
                textAlign: TextAlign.center,
                style: GoogleFonts.lato(
                  fontSize: 11,
                  color: Colors.white54,
                  fontStyle: FontStyle.italic,
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 20),

            // ─── Footer / Branding ──────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.graphic_eq, size: 14, color: AppColors.accentGold.withValues(alpha: 0.5)),
                const SizedBox(width: 6),
                Text(
                  'hunting-call-perfection.web.app',
                  style: GoogleFonts.lato(
                    fontSize: 10,
                    color: Colors.white24,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricColumn(String label, double value) {
    final Color color;
    if (value >= 80) {
      color = const Color(0xFF5FF7B6);
    } else if (value >= 50) {
      color = Colors.orangeAccent;
    } else {
      color = Colors.redAccent;
    }

    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.oswald(
            fontSize: 8,
            color: Colors.white38,
            letterSpacing: 1,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '${value.toInt()}',
          style: GoogleFonts.oswald(
            fontSize: 20,
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        // Mini progress bar
        SizedBox(
          width: 40,
          height: 3,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: value / 100,
              backgroundColor: Colors.white.withValues(alpha: 0.1),
              color: color,
              minHeight: 3,
            ),
          ),
        ),
      ],
    );
  }
}
