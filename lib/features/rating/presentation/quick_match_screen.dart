import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:outcall/core/services/remote_config/remote_config_service.dart';
import 'package:outcall/features/rating/data/fingerprint_service.dart';

/// Lightweight results screen for Quick Match mode.
///
/// Shows the fingerprint match result with a large animated score,
/// matched animal identification, and a simple tip. No waveform,
/// no AI coach, no detailed analytics — just fast results.
class QuickMatchScreen extends ConsumerStatefulWidget {
  final String audioPath;
  final String animalId;

  const QuickMatchScreen({
    super.key,
    required this.audioPath,
    required this.animalId,
  });

  @override
  ConsumerState<QuickMatchScreen> createState() => _QuickMatchScreenState();
}

class _QuickMatchScreenState extends ConsumerState<QuickMatchScreen>
    with SingleTickerProviderStateMixin {
  FingerprintResult? _result;
  bool _isLoading = true;
  String? _error;

  late AnimationController _scoreAnimController;
  late Animation<double> _scoreAnimation;

  @override
  void initState() {
    super.initState();
    _scoreAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _scoreAnimation = CurvedAnimation(
      parent: _scoreAnimController,
      curve: Curves.elasticOut,
    );
    _runFingerprint();
  }

  @override
  void dispose() {
    _scoreAnimController.dispose();
    super.dispose();
  }

  Future<void> _runFingerprint() async {
    try {
      final remoteConfig = ref.read(remoteConfigServiceProvider);
      final result = await FingerprintService.match(
        widget.audioPath,
        baseUrl: remoteConfig.aiCoachUrl,
      );
      if (mounted) {
        setState(() {
          _result = result;
          _isLoading = false;
        });
        _scoreAnimController.forward();

        // Haptic feedback based on score
        if (result.score >= 80) {
          HapticFeedback.mediumImpact();
        } else if (result.score >= 50) {
          HapticFeedback.lightImpact();
        } else {
          HapticFeedback.heavyImpact();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Could not reach the AI backend. Make sure it\'s running.';
          _isLoading = false;
        });
      }
    }
  }

  String _getQuickTip(double score) {
    if (score >= 90) return 'Incredible match! You sound just like the master.';
    if (score >= 75) return 'Great call! Minor tweaks to nail it.';
    if (score >= 50) return 'Good effort — try matching the rhythm and pitch more closely.';
    if (score >= 25) return 'Keep practicing — listen to the reference a few times first.';
    return 'Try again in a quieter spot, closer to the mic.';
  }

  Color _scoreColor(double score) {
    if (score >= 85) return const Color(0xFF5FF7B6);
    if (score >= 70) return const Color(0xFF4FC3F7);
    if (score >= 50) return const Color(0xFFFFD54F);
    return const Color(0xFFFF5252);
  }

  IconData _scoreIcon(double score) {
    if (score >= 85) return Icons.emoji_events_rounded;
    if (score >= 70) return Icons.thumb_up_rounded;
    if (score >= 50) return Icons.trending_up_rounded;
    return Icons.refresh_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('QUICK MATCH',
            style: GoogleFonts.oswald(
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
                fontSize: 16,
                color: Colors.white)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/forest_background.png'),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(Colors.black54, BlendMode.darken),
          ),
        ),
        child: SafeArea(
          child: _isLoading
              ? _buildLoading()
              : _error != null
                  ? _buildError()
                  : _buildResult(),
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 80,
            height: 80,
            child: CircularProgressIndicator(
              color: Color(0xFF5FF7B6),
              strokeWidth: 6,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'MATCHING YOUR CALL',
            style: GoogleFonts.oswald(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Comparing against master fingerprints...',
            style: GoogleFonts.lato(fontSize: 13, color: Colors.white60),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.redAccent.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.wifi_off_rounded,
                  color: Colors.redAccent, size: 64),
            ),
            const SizedBox(height: 32),
            Text(
              'CONNECTION ERROR',
              style: GoogleFonts.oswald(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: GoogleFonts.lato(fontSize: 16, color: Colors.white70),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _error = null;
                  });
                  _runFingerprint();
                },
                icon: const Icon(Icons.refresh_rounded),
                label: Text('TRY AGAIN',
                    style: GoogleFonts.oswald(
                        letterSpacing: 1.5, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5FF7B6),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResult() {
    final result = _result!;
    final score = result.score;
    final color = _scoreColor(score);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 40),

          // Score circle
          AnimatedBuilder(
            animation: _scoreAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: 0.5 + (_scoreAnimation.value * 0.5),
                child: Opacity(
                  opacity: _scoreAnimation.value.clamp(0.0, 1.0),
                  child: child,
                ),
              );
            },
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: color.withValues(alpha: 0.6), width: 4),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    blurRadius: 40,
                    spreadRadius: 10,
                  ),
                ],
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${score.toStringAsFixed(0)}%',
                      style: GoogleFonts.oswald(
                        fontSize: 56,
                        fontWeight: FontWeight.bold,
                        color: color,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'MATCH',
                      style: GoogleFonts.oswald(
                        fontSize: 14,
                        color: Colors.white54,
                        letterSpacing: 3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 32),

          // Matched animal
          if (result.hasMatch) ...[
            Icon(_scoreIcon(score), color: color, size: 32),
            const SizedBox(height: 12),
            Text(
              result.matchLabel,
              style: GoogleFonts.oswald(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Matched in ${result.elapsedMs.toStringAsFixed(0)}ms',
                style: GoogleFonts.lato(
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ] else ...[
            const Icon(Icons.help_outline_rounded,
                color: Colors.white38, size: 32),
            const SizedBox(height: 12),
            Text(
              'No Match Found',
              style: GoogleFonts.oswald(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white54,
                letterSpacing: 1,
              ),
            ),
          ],

          const SizedBox(height: 32),

          // Quick tip
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.lightbulb_outline_rounded,
                    color: Color(0xFFFFD54F), size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _getQuickTip(score),
                    style: GoogleFonts.lato(
                      fontSize: 15,
                      color: Colors.white70,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 40),

          // Action buttons
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.replay_rounded),
              label: Text('TRY AGAIN',
                  style: GoogleFonts.oswald(
                      letterSpacing: 1.5, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5FF7B6),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                // Pop back to recorder, user can switch to Expert mode
                Navigator.of(context).pop('switch_to_expert');
              },
              icon: const Icon(Icons.analytics_rounded),
              label: Text('GO EXPERT',
                  style: GoogleFonts.oswald(
                      letterSpacing: 1.5, fontWeight: FontWeight.bold)),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white24),
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
