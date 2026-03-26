import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:outcall/core/services/analytics_service.dart';
import 'package:outcall/core/services/cloud_audio_service.dart';
import 'package:outcall/core/utils/app_logger.dart';
import 'package:outcall/core/widgets/achievement_overlay.dart';
import 'package:outcall/di_providers.dart' show appRatingServiceProvider;
import 'package:outcall/features/auth/presentation/controllers/auth_controller.dart';
import 'package:outcall/features/library/domain/providers.dart';
import 'package:outcall/features/profile/domain/achievement_service.dart';
import 'package:outcall/features/profile/presentation/controllers/profile_controller.dart';
import 'package:outcall/features/rating/domain/rating_model.dart';
import 'package:outcall/features/rating/presentation/controllers/rating_controller.dart';
import 'package:outcall/features/rating/presentation/widgets/ai_coach_card.dart';
import 'package:outcall/features/rating/presentation/widgets/rating_action_buttons.dart';
import 'package:outcall/features/rating/presentation/widgets/rating_analytics_widgets.dart';
import 'package:outcall/features/rating/presentation/widgets/rating_feedback_widgets.dart';
import 'package:outcall/features/rating/presentation/widgets/waveform_overlay.dart';
import 'package:outcall/l10n/app_localizations.dart';
import 'package:outcall/core/theme/app_colors.dart';

class RatingScreen extends ConsumerStatefulWidget {
  final String audioPath;
  final String animalId;
  final String userId;
  const RatingScreen(
      {super.key, required this.audioPath, required this.animalId, required this.userId});

  @override
  ConsumerState<RatingScreen> createState() => _RatingScreenState();
}

class _RatingScreenState extends ConsumerState<RatingScreen> {
  final ScrollController _scrollController = ScrollController();
  final AudioPlayer _userPlayer = AudioPlayer();
  final AudioPlayer _refPlayer = AudioPlayer();

  bool _isUserPlaying = false;
  bool _isRefPlaying = false;
  bool _isReviewing = true;

  @override
  void dispose() {
    _scrollController.dispose();
    _userPlayer.dispose();
    _refPlayer.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    // Set up player listeners
    _userPlayer.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _isUserPlaying = false);
    });

    _refPlayer.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _isRefPlaying = false);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Clear any previous results but wait for user to start analysis
      ref.read(ratingNotifierProvider.notifier).reset();
    });
  }

  void _startAnalysis() {
    if (_isUserPlaying) {
      _userPlayer.stop();
      setState(() => _isUserPlaying = false);
    }
    setState(() => _isReviewing = false);
    ref.read(ratingNotifierProvider.notifier).analyzeCall(
          widget.userId,
          widget.audioPath,
          widget.animalId,
        );
  }

  Future<void> _toggleUserPlayback() async {
    if (_isUserPlaying) {
      await _userPlayer.stop();
      if (mounted) setState(() => _isUserPlaying = false);
    } else {
      // Ensure other player is stopped
      if (_isRefPlaying) {
        await _refPlayer.stop();
        if (mounted) setState(() => _isRefPlaying = false);
      }

      try {
        await _userPlayer.play(DeviceFileSource(widget.audioPath));
        if (mounted) setState(() => _isUserPlaying = true);
      } catch (e) {
        AppLogger.d('Error playing user audio: $e');
      }
    }
  }

  Future<void> _toggleReferencePlayback() async {
    if (_isRefPlaying) {
      await _refPlayer.stop();
      if (mounted) setState(() => _isRefPlaying = false);
    } else {
      // Ensure other player is stopped
      if (_isUserPlaying) {
        await _userPlayer.stop();
        if (mounted) setState(() => _isUserPlaying = false);
      }

      final getCallUseCase = ref.read(getCallByIdUseCaseProvider);
      final result = getCallUseCase.execute(widget.animalId);

      result.fold(
        (failure) => AppLogger.d('Error getting reference call: ${failure.message}'),
        (reference) async {
          final cloudAudio = ref.read(cloudAudioServiceProvider);

          try {
            final source =
                await cloudAudio.resolveAudioSource(reference.id, reference.audioAssetPath);
            if (source.isAsset) {
              await _refPlayer.play(AssetSource(source.path));
            } else {
              await _refPlayer.play(DeviceFileSource(source.path));
            }
            if (mounted) setState(() => _isRefPlaying = true);
          } catch (e) {
            AppLogger.d('Error playing reference audio: $e');
          }
        },
      );
    }
  }

  void _triggerResultHaptics(RatingResult? result) {
    if (result == null) return;

    // Different haptics based on score
    if (result.score >= 85) {
      HapticFeedback.mediumImpact();
    } else if (result.score >= 60) {
      HapticFeedback.mediumImpact();
    } else {
      HapticFeedback.heavyImpact();
    }
  }

  /// Check for newly earned achievements after analysis and show celebration overlays.
  /// #7: Optimized from 3 Firestore round-trips to 1 save operation.
  Future<void> _checkForAchievements() async {
    final profile = ref.read(profileNotifierProvider).profile;
    if (profile == null || profile.id == 'guest') return;

    // Use the current in-memory profile instead of re-loading from Firestore
    final newIds = AchievementService.getNewAchievementIds(
      profile,
      profile.achievements,
    );

    if (newIds.isEmpty) return;

    // Persist new achievements (single Firestore write)
    final allAchievements = {...profile.achievements, ...newIds}.toList();
    await ref.read(profileNotifierProvider.notifier).saveAchievementsForUser(
          profile.id,
          allAchievements,
        );

    // Show each new achievement with staggered delay
    for (int i = 0; i < newIds.length; i++) {
      final achievement = AchievementService.achievements.firstWhere(
        (a) => a.id == newIds[i],
      );
      Future.delayed(Duration(milliseconds: 800 + (i * 3500)), () {
        if (mounted) {
          AchievementOverlay.show(
            context,
            name: achievement.name,
            icon: achievement.icon,
            description: achievement.description,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen for completion to trigger haptics
    ref.listen<RatingState>(ratingNotifierProvider, (previous, next) {
      if (previous?.isAnalyzing == true && next.isAnalyzing == false) {
        if (next.result != null) {
          _triggerResultHaptics(next.result);
          // Check for achievement unlocks
          _checkForAchievements();
          // Track analytics
          AnalyticsService.logRecordingCompleted(widget.animalId, next.result!.score);
          // Maybe prompt for app review after a high score
          if (next.result!.score >= 80) {
            ref.read(appRatingServiceProvider).maybePromptReview();
          }
        } else if (next.error != null) {
          HapticFeedback.vibrate();
        }
      }
    });

    final ratingState = ref.watch(ratingNotifierProvider);
    final result = ratingState.result;
    final isLoading = ratingState.isAnalyzing;
    final error = ratingState.error;

    // Calculate safe top padding to prevent AppBar overlap
    final topPadding = MediaQuery.of(context).padding.top + kToolbarHeight + 20;

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(S.of(context).analysisResult,
            style: GoogleFonts.oswald(
                fontWeight: FontWeight.bold, letterSpacing: 2, fontSize: 16, color: Colors.white)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (!ref.watch(firebaseEnabledProvider))
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Center(
                child: Tooltip(
                  message: 'Off-Grid Mode: Cloud Sync Disabled',
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.cloud_off, color: Colors.orangeAccent, size: 16),
                      const SizedBox(width: 4),
                      Text(S.of(context).offGrid,
                          style: const TextStyle(
                              color: Colors.orangeAccent,
                              fontSize: 10,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ),
        ],
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
            image: AssetImage('assets/images/forest_background.webp'),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(Colors.black54, BlendMode.darken),
          ),
        ),
        child: _isReviewing
            ? _buildReviewState()
            : isLoading
                ? Center(
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 80),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(
                              width: 80,
                              height: 80,
                              child: CircularProgressIndicator(
                                color: AppColors.success,
                                strokeWidth: 6,
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
                              'Extracting frequency patterns...',
                              style: GoogleFonts.lato(
                                fontSize: 13,
                                color: Colors.white60,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                : error != null
                    ? Center(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(32.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: Colors.redAccent.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.mic_off_rounded,
                                    color: Colors.redAccent, size: 64),
                              ),
                              const SizedBox(height: 32),
                              Text(
                                'ANALYSIS FAILED',
                                style: GoogleFonts.oswald(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 2,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                error,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.lato(fontSize: 16, color: Colors.white70),
                              ),
                              const SizedBox(height: 40),
                              const GuidanceCard(
                                icon: Icons.volume_mute,
                                title: 'QUIETER ENVIRONMENT',
                                subtitle: 'Move away from wind or loud machinery.',
                              ),
                              const SizedBox(height: 12),
                              const GuidanceCard(
                                icon: Icons.settings_voice,
                                title: 'CLOSER MIC',
                                subtitle: 'Hold the device closer to your mouth.',
                              ),
                              const SizedBox(height: 48),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    ref.read(ratingNotifierProvider.notifier).reset();
                                    ref.read(ratingNotifierProvider.notifier).analyzeCall(
                                          widget.userId,
                                          widget.audioPath,
                                          widget.animalId,
                                        );
                                  },
                                  icon: const Icon(Icons.refresh_rounded),
                                  label: Text(S.of(context).tryAgain,
                                      style: GoogleFonts.oswald(
                                          letterSpacing: 1.5, fontWeight: FontWeight.bold)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.success,
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
                      )
                    : result == null
                        ? const Center(child: CircularProgressIndicator(color: AppColors.success))
                        : Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 600),
                              child: Scrollbar(
                                controller: _scrollController,
                                thumbVisibility: true,
                                trackVisibility: true,
                                child: ListView(
                                  controller: _scrollController,
                                  primary: false,
                                  addAutomaticKeepAlives: false,
                                  padding: EdgeInsets.fromLTRB(20, topPadding, 20, 80),
                                  children: [
                                    _tryRender(() => OverallProficiency(score: result.score),
                                        'Proficiency'),
                                    const SizedBox(height: 40),
                                    _tryRender(() => AIFeedbackCard(feedback: result.feedback),
                                        'Feedback'),
                                    const SizedBox(height: 16),
                                    _tryRender(() => PersonalityFeedbackCard(score: result.score),
                                        'Personality'),
                                    const SizedBox(height: 24),
                                    _tryRender(
                                        () => AiCoachCard(
                                              result: result,
                                              animalId: widget.animalId,
                                              audioPath: widget.audioPath,
                                            ),
                                        'AI Coach'),
                                    const SizedBox(height: 32),
                                    _tryRender(
                                        () => _buildPitchComparison(result), 'Pitch Comparison'),
                                    const SizedBox(height: 24),
                                    if (result.userWaveform != null)
                                      WaveformOverlay(
                                        userWaveform: result.userWaveform!,
                                        referenceWaveform: result.referenceWaveform,
                                        onPlayUser: _toggleUserPlayback,
                                        onPlayReference: _toggleReferencePlayback,
                                        isUserPlaying: _isUserPlaying,
                                        isReferencePlaying: _isRefPlaying,
                                      ),
                                    const SizedBox(height: 24),
                                    _tryRender(() => ProBreakdown(result: result), 'Pro Breakdown'),
                                    const SizedBox(height: 16),
                                    _tryRender(
                                        () => PrimaryFlawCard(result: result), 'Primary Flaw'),
                                    const SizedBox(height: 24),
                                    _tryRender(() => _buildDetailedMetrics(result), 'Metrics'),
                                    const SizedBox(height: 40),
                                    _tryRender(() => ComprehensiveAnalyticsSection(result: result),
                                        'Analytics'),
                                    const SizedBox(height: 40),
                                    _tryRender(() => const RatingTipSection(), 'Tip'),
                                    const SizedBox(height: 32),
                                    RatingActionButtons(
                                        result: result,
                                        audioPath: widget.audioPath,
                                        animalId: widget.animalId),
                                  ],
                                ),
                              ),
                            ),
                          ),
      ),
    );
  }

  Widget _buildReviewState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.headphones_rounded, color: AppColors.success, size: 64),
            ),
            const SizedBox(height: 32),
            Text(
              'REVIEW RECORDING',
              style: GoogleFonts.oswald(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Listen to your call before submitting it for AI analysis.',
              textAlign: TextAlign.center,
              style: GoogleFonts.lato(fontSize: 16, color: Colors.white70),
            ),
            const SizedBox(height: 48),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FloatingActionButton.large(
                  heroTag: 'play_user_audio_btn',
                  onPressed: _toggleUserPlayback,
                  tooltip: _isUserPlaying ? 'Stop playback' : 'Play your recording',
                  backgroundColor: _isUserPlaying ? Colors.white : AppColors.success,
                  child: Icon(
                    _isUserPlaying ? Icons.stop_rounded : Icons.play_arrow_rounded,
                    color: Colors.black,
                    size: 40,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              _isUserPlaying ? 'PLAYING...' : 'PLAY AUDIO',
              style: GoogleFonts.oswald(fontSize: 12, color: Colors.white54, letterSpacing: 1),
            ),
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _startAnalysis,
                icon: const Icon(Icons.analytics_rounded),
                label: Text(S.of(context).scoreMyCall,
                    style: GoogleFonts.oswald(letterSpacing: 1.5, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                foregroundColor: Colors.white70,
              ),
              child: Text(S.of(context).discardAndRetry),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tryRender(Widget Function() builder, String sectionName) {
    try {
      return builder();
    } catch (e, stack) {
      AppLogger.d('RENDER ERROR in $sectionName: $e\n$stack');
      return Container(
        padding: const EdgeInsets.all(8),
        color: Colors.red.withValues(alpha: 0.2),
        child: Text('Error in $sectionName: $e',
            style: const TextStyle(color: Colors.red, fontSize: 10)),
      );
    }
  }

  Widget _buildPitchComparison(RatingResult result) {
    final getCallUseCase = ref.read(getCallByIdUseCaseProvider);
    final callResult = getCallUseCase.execute(widget.animalId);

    return callResult.fold(
      (failure) => Container(
        padding: const EdgeInsets.all(20),
        child: Text('Error loading reference: ${failure.message}',
            style: GoogleFonts.lato(color: Colors.redAccent)),
      ),
      (reference) {
        final targetPitch = _toSafe(reference.idealPitchHz);
        final userPitch = _toSafe(result.pitchHz);
        final diff = userPitch - targetPitch;
        final isTooHigh = diff > 0;

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
          ),
          child: Column(
            children: [
              Text(S.of(context).pitchComparison,
                  style: GoogleFonts.oswald(
                      fontSize: 11,
                      letterSpacing: 1.5,
                      color: Colors.white,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    children: [
                      Text(S.of(context).target,
                          style: GoogleFonts.oswald(
                              fontSize: 9, color: Colors.white38, letterSpacing: 1)),
                      const SizedBox(height: 4),
                      Text('${targetPitch.toInt()} Hz',
                          style: GoogleFonts.oswald(
                              fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Column(
                    children: [
                      Icon(isTooHigh ? Icons.arrow_upward : Icons.arrow_downward,
                          color: AppColors.success, size: 20),
                      const SizedBox(height: 2),
                      Text(isTooHigh ? 'TOO HIGH' : 'TOO LOW',
                          style: GoogleFonts.oswald(
                              fontSize: 9, color: Colors.white70, fontWeight: FontWeight.bold)),
                      Text('${diff.abs().toInt()} Hz',
                          style: GoogleFonts.lato(fontSize: 9, color: Colors.white38)),
                    ],
                  ),
                  Column(
                    children: [
                      Text(S.of(context).yourPitch,
                          style: GoogleFonts.oswald(
                              fontSize: 9, color: Colors.white38, letterSpacing: 1)),
                      const SizedBox(height: 4),
                      Text('${userPitch.toInt()} Hz',
                          style: GoogleFonts.oswald(
                              fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildPitchSlider(userPitch, targetPitch, reference.tolerancePitch),
              const SizedBox(height: 12),
              Builder(builder: (_) {
                final isWithinTolerance = (userPitch - targetPitch).abs() <= reference.tolerancePitch;
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isWithinTolerance
                        ? AppColors.success.withValues(alpha: 0.15)
                        : Colors.redAccent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isWithinTolerance ? 'Within tolerance ✔' : 'Outside tolerance ✘',
                    style: GoogleFonts.lato(
                      fontSize: 10,
                      color: isWithinTolerance ? AppColors.success : Colors.redAccent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPitchSlider(double user, double target, double tolerance) {
    return SizedBox(
      height: 30,
      child: LayoutBuilder(
        builder: (context, constraints) {
          const minFreq = 100.0;
          const maxFreq = 1000.0;

          double normalize(double val) => ((val - minFreq) / (maxFreq - minFreq)).clamp(0, 1);

          final targetNorm = normalize(target);
          final userNorm = normalize(user);
          final toleranceNorm = (tolerance / (maxFreq - minFreq)).clamp(0, 0.4);

          final maxWidth = constraints.maxWidth;
          final targetPos = targetNorm * maxWidth;
          final toleranceWidth = toleranceNorm * maxWidth * 2;

          return Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.centerLeft,
            children: [
              // 1. Background Track
              Container(
                height: 6,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),

              // 2. Tolerance Zone
              Positioned(
                left: (targetPos - toleranceWidth / 2).clamp(0, maxWidth),
                width: (toleranceWidth)
                    .clamp(0, maxWidth - (targetPos - toleranceWidth / 2).clamp(0, maxWidth)),
                height: 6,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(3),
                    border: Border.all(
                        color: AppColors.success.withValues(alpha: 0.1), width: 0.5),
                  ),
                ),
              ),

              // 3. Target Mark
              Positioned(
                left: targetPos - 1,
                width: 2,
                height: 12,
                child: Container(
                  color: Colors.white.withValues(alpha: 0.4),
                ),
              ),

              // 4. User Indicator (Animated)
              TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 1000),
                curve: Curves.elasticOut,
                tween: Tween(begin: 0.0, end: userNorm),
                builder: (context, animUserNorm, child) {
                  final animatedUserPos = animUserNorm * maxWidth;
                  return Positioned(
                    left: (animatedUserPos - 4).clamp(0, maxWidth - 8),
                    width: 8,
                    height: 8,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                              color: AppColors.success.withValues(alpha: 0.5),
                              blurRadius: 8,
                              spreadRadius: 2)
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDetailedMetrics(RatingResult result) {
    final getCallUseCase = ref.read(getCallByIdUseCaseProvider);
    final callResult = getCallUseCase.execute(widget.animalId);

    return callResult.fold(
      (failure) =>
          Text('Error: ${failure.message}', style: GoogleFonts.lato(color: Colors.redAccent)),
      (reference) => Column(
        children: [
          _buildMetricRow(
              'PITCH (HZ)', 'Your frequency', '${_toSafe(result.pitchHz).toStringAsFixed(1)} Hz'),
          const SizedBox(height: 8),
          _buildMetricRow('TARGET PITCH', 'Ideal frequency',
              '${_toSafe(reference.idealPitchHz).toStringAsFixed(1)} Hz'),
          const SizedBox(height: 8),
          _buildMetricRow('DURATION (S)', 'Call length',
              "${_toSafe(result.metrics['Duration (s)'] ?? 1.0).toStringAsFixed(2)} s"),
        ],
      ),
    );
  }

  Widget _buildMetricRow(String label, String sublabel, String value) {
    return Semantics(
      label: '$label: $value',
      child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: ExcludeSemantics(
        child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: GoogleFonts.oswald(
                        fontSize: 10,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                Text(sublabel, style: GoogleFonts.lato(fontSize: 9, color: Colors.white38),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(value,
                style: GoogleFonts.oswald(
                    fontSize: 13, color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      ),
    ),
    );
  }

  double _toSafe(dynamic val) {
    if (val == null) return 0.0;
    if (val is num) return val.isFinite ? val.toDouble() : 0.0;
    return double.tryParse(val.toString()) ?? 0.0;
  }
}
