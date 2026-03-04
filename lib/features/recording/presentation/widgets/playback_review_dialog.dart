import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:outcall/core/theme/app_colors.dart';

/// Shows a modal that lets the user listen back to their recording before
/// submitting it for analysis.
///
/// Returns `true` if the user wants to continue to analysis,
/// `false` if they want to re-record.
Future<bool> showPlaybackReviewDialog(BuildContext context, String audioPath) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isDismissible: false,
    enableDrag: false,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _PlaybackReviewSheet(audioPath: audioPath),
  );
  return result ?? false; // Default to re-record if dismissed
}

class _PlaybackReviewSheet extends StatefulWidget {
  final String audioPath;
  const _PlaybackReviewSheet({required this.audioPath});

  @override
  State<_PlaybackReviewSheet> createState() => _PlaybackReviewSheetState();
}

class _PlaybackReviewSheetState extends State<_PlaybackReviewSheet> {
  final AudioPlayer _player = AudioPlayer();
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  StreamSubscription? _positionSub;
  StreamSubscription? _durationSub;
  StreamSubscription? _completeSub;

  @override
  void initState() {
    super.initState();
    _positionSub = _player.onPositionChanged.listen((p) {
      if (mounted) setState(() => _position = p);
    });
    _durationSub = _player.onDurationChanged.listen((d) {
      if (mounted) setState(() => _duration = d);
    });
    _completeSub = _player.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() {
          _isPlaying = false;
          _position = Duration.zero;
        });
      }
    });
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _durationSub?.cancel();
    _completeSub?.cancel();
    _player.dispose();
    super.dispose();
  }

  Future<void> _togglePlayback() async {
    if (_isPlaying) {
      await _player.pause();
      setState(() => _isPlaying = false);
    } else {
      await _player.play(DeviceFileSource(widget.audioPath));
      setState(() => _isPlaying = true);
    }
  }

  String _formatDuration(Duration d) {
    final min = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final sec = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$min:$sec';
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final primary = Theme.of(context).primaryColor;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: primary.withValues(alpha: 0.3), width: 2)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag indicator
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'REVIEW YOUR RECORDING',
              style: GoogleFonts.oswald(
                color: colors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Listen back before analyzing',
              style: GoogleFonts.lato(color: colors.textSubtle, fontSize: 13),
            ),
            const SizedBox(height: 24),

            // Playback controls
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _formatDuration(_position),
                  style: GoogleFonts.lato(color: colors.textTertiary, fontSize: 12),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: _togglePlayback,
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: primary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: primary.withValues(alpha: 0.3), blurRadius: 12, spreadRadius: 2),
                      ],
                    ),
                    child: Icon(
                      _isPlaying ? Icons.pause : Icons.play_arrow,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  _formatDuration(_duration),
                  style: GoogleFonts.lato(color: colors.textTertiary, fontSize: 12),
                ),
              ],
            ),

            // Progress bar
            if (_duration.inMilliseconds > 0) ...[
              const SizedBox(height: 12),
              SliderTheme(
                data: SliderThemeData(
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                  activeTrackColor: primary,
                  inactiveTrackColor: colors.border,
                  thumbColor: primary,
                ),
                child: Slider(
                  value: _position.inMilliseconds.toDouble().clamp(0, _duration.inMilliseconds.toDouble()),
                  max: _duration.inMilliseconds.toDouble(),
                  onChanged: (v) async {
                    await _player.seek(Duration(milliseconds: v.toInt()));
                  },
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      _player.stop();
                      Navigator.pop(context, false);
                    },
                    icon: const Icon(Icons.refresh, size: 18),
                    label: Text('RE-RECORD', style: GoogleFonts.oswald(fontWeight: FontWeight.bold, letterSpacing: 1)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colors.textTertiary,
                      side: BorderSide(color: colors.border),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      _player.stop();
                      Navigator.pop(context, true);
                    },
                    icon: const Icon(Icons.analytics_outlined, size: 18),
                    label: Text('ANALYZE', style: GoogleFonts.oswald(fontWeight: FontWeight.bold, letterSpacing: 1)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
