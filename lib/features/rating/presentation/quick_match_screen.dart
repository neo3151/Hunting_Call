import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:outcall/di_providers.dart';
import 'package:outcall/features/library/data/reference_database.dart';
import 'package:outcall/features/profile/presentation/controllers/profile_controller.dart';
import 'package:outcall/features/rating/domain/rating_model.dart';

/// Lightweight results screen for Quick Match mode.
///
/// Runs on-device scoring (DSP analysis) to produce a fast match result.
/// Shows the score, matched animal, and a simple tip.
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
  RatingResult? _result;
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
    _runAnalysis();
  }

  @override
  void dispose() {
    _scoreAnimController.dispose();
    super.dispose();
  }

  Future<void> _runAnalysis() async {
    try {
      final ratingService = ref.read(ratingServiceProvider);
      final profile = ref.read(profileNotifierProvider).profile;
      final userId = profile?.id ?? 'guest';

      final result = await ratingService.rateCall(
        userId,
        widget.audioPath,
        widget.animalId,
        skipFingerprint: true, // Quick Match runs pure on-device DSP
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
          _error = 'Analysis failed: ${e.toString().replaceAll('Exception: ', '')}';
          _isLoading = false;
        });
      }
    }
  }

  String _getQuickTip(double score) {
    if (score >= 90) return 'Nearly perfect! Competition-ready technique.';
    if (score >= 80) return 'Great match — try opening your throat slightly for richer tone.';
    if (score >= 70) return 'Solid call! Slow your cadence slightly on the second note.';
    if (score >= 55) return 'Good start — focus on matching the pitch rise and rhythm pattern.';
    if (score >= 35) return 'Listen to the reference closely, then match the timing and volume.';
    return 'Try again in a quieter spot — relax your air pressure and let the call flow.';
  }

  /// Encouraging headline shown above the animal name.
  String _scoreHeadline(double score) {
    if (score >= 80) return '🔥 EXPERT LEVEL!';
    if (score >= 60) return '🎯 NICE CALL!';
    if (score >= 30) return '👏 GREAT START!';
    if (score >= 10) return '💪 KEEP GOING!';
    return '🎤 FIRST STEPS!';
  }

  /// Map animal name to emoji for visual flair.
  String _animalEmoji(String animal) {
    final key = animal.toLowerCase();
    const map = {
      'turkey': '🦃',
      'elk': '🫎',
      'deer': '🦌',
      'duck': '🦆',
      'goose': '🪿',
      'owl': '🦉',
      'hawk': '🦅',
      'crow': '🐦‍⬛',
      'coyote': '🐺',
      'wolf': '🐺',
      'bear': '🐻',
      'fox': '🦊',
      'bobcat': '🐱',
      'cougar': '🐆',
      'rabbit': '🐇',
      'pheasant': '🐔',
      'quail': '🐤',
      'dove': '🕊️',
      'hog': '🐗',
    };
    // Check if any key is contained in the animal name
    for (final entry in map.entries) {
      if (key.contains(entry.key)) return entry.value;
    }
    return '🎯';
  }

  Color _scoreColor(double score) {
    if (score >= 85) return const Color(0xFF5FF7B6);
    if (score >= 70) return const Color(0xFF4FC3F7);
    if (score >= 50) return const Color(0xFFFFD54F);
    return const Color(0xFFFF5252);
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
      child: SingleChildScrollView(
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
          ),
          const SizedBox(height: 32),
          Text(
            'ANALYZING YOUR CALL',
            style: GoogleFonts.oswald(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Running on-device DSP analysis...',
            style: GoogleFonts.lato(fontSize: 13, color: Colors.white60),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFFFD54F).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.error_outline_rounded,
                  color: Colors.redAccent, size: 64),
            ),
            const SizedBox(height: 32),
            Text(
              'ANALYSIS ERROR',
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
              style: GoogleFonts.lato(fontSize: 15, color: Colors.white70, height: 1.5),
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
                  _runAnalysis();
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
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Go Back',
                  style: GoogleFonts.lato(color: Colors.white38, fontSize: 14)),
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

    // Get the animal name from the reference database
    final reference = ReferenceDatabase.getById(widget.animalId);
    final animalName = reference.animalName;
    final callType = reference.callType;

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

          const SizedBox(height: 24),

          // Encouraging headline
          Text(
            _scoreHeadline(score),
            style: GoogleFonts.oswald(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
              letterSpacing: 1.5,
            ),
          ),

          const SizedBox(height: 16),

          // Matched animal with emoji
          Text(
            _animalEmoji(animalName),
            style: const TextStyle(fontSize: 48),
          ),
          const SizedBox(height: 8),
          Text(
            '$animalName $callType',
            style: GoogleFonts.oswald(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 1,
            ),
          ),

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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getQuickTip(score),
                        style: GoogleFonts.lato(
                          fontSize: 15,
                          color: Colors.white70,
                          height: 1.4,
                        ),
                      ),
                      if (result.feedback.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          result.feedback,
                          style: GoogleFonts.lato(
                            fontSize: 13,
                            color: Colors.white38,
                            height: 1.3,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
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
              onPressed: () => Navigator.of(context).pop('retry'),
              icon: const Icon(Icons.mic_rounded),
              label: Text('RECORD AGAIN',
                  style: GoogleFonts.oswald(
                      fontSize: 16, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
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
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop('switch_to_expert');
                  },
                  icon: const Icon(Icons.analytics_rounded, size: 18),
                  label: Text('GO EXPERT',
                      style: GoogleFonts.oswald(
                          letterSpacing: 1.5, fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white24),
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.check_rounded, size: 18),
                  label: Text('DONE',
                      style: GoogleFonts.oswald(
                          letterSpacing: 1.5, fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white70,
                    side: const BorderSide(color: Colors.white12),
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
