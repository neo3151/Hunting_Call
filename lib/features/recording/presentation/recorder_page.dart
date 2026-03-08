import 'dart:async';
import 'dart:io' show Platform;
import 'dart:ui';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:outcall/core/services/cloud_audio_service.dart';
import 'package:outcall/core/theme/app_colors.dart';
import 'package:outcall/core/utils/app_logger.dart';
import 'package:outcall/core/widgets/background_wrapper.dart';
import 'package:outcall/features/library/data/reference_database.dart';
import 'package:outcall/features/library/presentation/category_grid_screen.dart';
import 'package:outcall/features/profile/presentation/controllers/profile_controller.dart';
import 'package:outcall/features/rating/presentation/rating_screen.dart';
import 'package:outcall/features/recording/presentation/controllers/recording_controller.dart';
import 'package:outcall/features/recording/presentation/widgets/playback_review_dialog.dart';
import 'package:outcall/features/recording/presentation/widgets/preflight_check_modal.dart';
import 'package:outcall/features/recording/presentation/widgets/recorder_coaching.dart';
import 'package:outcall/features/recording/presentation/widgets/recorder_dialogs.dart';
import 'package:outcall/features/recording/presentation/widgets/recorder_widgets.dart';
import 'package:outcall/l10n/app_localizations.dart';
import 'package:permission_handler/permission_handler.dart';

class RecorderPage extends ConsumerStatefulWidget {
  final String userId;
  final String? preselectedAnimalId;

  const RecorderPage({super.key, required this.userId, this.preselectedAnimalId});

  @override
  ConsumerState<RecorderPage> createState() => _RecorderPageState();
}

class _RecorderPageState extends ConsumerState<RecorderPage> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool isPlayingReference = false;
  StreamSubscription? _playerCompleteSubscription;
  Timer? _autoStopTimer;

  // New: Amplitude buffer for smooth visualization
  final List<double> _amplitudeBuffer = [];
  ProviderSubscription<AsyncValue<double>>? _amplitudeSubscription;

  @override
  void initState() {
    super.initState();

    // Initialize selected call
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.preselectedAnimalId != null) {
        ref.read(selectedCallIdProvider.notifier).setCallId(widget.preselectedAnimalId!);
      } else {
        final isPremium = ref.read(profileNotifierProvider).profile?.isPremium ?? false;
        final availableCalls = ReferenceDatabase.calls
            .where((c) => !ReferenceDatabase.isLocked(c.id, isPremium))
            .toList();

        if (availableCalls.isNotEmpty) {
          ref.read(selectedCallIdProvider.notifier).setCallId(availableCalls.first.id);
        } else {
          ref.read(selectedCallIdProvider.notifier).setCallId(ReferenceDatabase.calls.first.id);
        }
      }
    });

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(_pulseController);

    _playerCompleteSubscription = _audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) setState(() => isPlayingReference = false);
    });

    // Subscribe to amplitude stream
    _amplitudeSubscription = ref.listenManual(amplitudeStreamProvider, (prev, next) {
      if (next.hasValue && next.value != null && mounted) {
        setState(() {
          _amplitudeBuffer.add(next.value!);
          // Keep buffer size manageable (approx 5 seconds of history at 50ms intervals = 100 samples)
          if (_amplitudeBuffer.length > 100) {
            _amplitudeBuffer.removeAt(0);
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _autoStopTimer?.cancel();
    _playerCompleteSubscription?.cancel();
    _amplitudeSubscription?.close();
    _audioPlayer.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  String _formatDuration(int seconds) {
    final int minutes = seconds ~/ 60;
    final int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  // Coaching logic delegated to recorder_coaching.dart
  double _computeRefAvg(List<double>? waveform) => computeReferenceAverage(waveform);
  ({String text, Color color}) _getCoachingFeedback(double refAvg) =>
      getCoachingFeedback(_amplitudeBuffer, refAvg);

  bool isProcessing = false;

  void _resetRecording() async {
    if (isProcessing) return;
    _autoStopTimer?.cancel();
    await HapticFeedback.selectionClick();

    setState(() => isProcessing = true);
    try {
      await ref.read(recordingNotifierProvider.notifier).reset();
    } finally {
      if (mounted) {
        setState(() {
          _amplitudeBuffer.clear();
          isProcessing = false;
        });
      }
    }
  }

  void _toggleRecording() async {
    if (isProcessing) return;

    final notifier = ref.read(recordingNotifierProvider.notifier);
    final recordingState = ref.read(recordingNotifierProvider);
    final selectedCallId = ref.read(selectedCallIdProvider);

    try {
      if (recordingState.isRecording) {
        // Stopping recording
        setState(() => isProcessing = true);
        await HapticFeedback.mediumImpact();

        try {
          final path = await notifier.stopRecording();

          if (mounted) {
            if (path != null && path.isNotEmpty && !path.contains('not open')) {
              // Show playback review before analysis
              final shouldAnalyze = await showPlaybackReviewDialog(context, path);
              if (!mounted) return;
              if (shouldAnalyze) {
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => RatingScreen(
                          audioPath: path,
                          animalId: selectedCallId,
                          userId: widget.userId,
                        )));
              } else {
                _resetRecording();
              }
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Recording Failed: Could not save audio file.')),
              );
            }
          }
        } finally {
          if (mounted) setState(() => isProcessing = false);
        }
      } else {
        // Starting recording
        if (!Platform.isLinux) {
          final permissionStatus = await Permission.microphone.status;

          if (permissionStatus.isDenied) {
            final granted = await Permission.microphone.request();
            if (!granted.isGranted) {
              if (mounted) showMicPermissionDeniedDialog(context, onGranted: _toggleRecording);
              return;
            }
          } else if (permissionStatus.isPermanentlyDenied) {
            if (mounted) showMicPermissionSettingsDialog(context);
            return;
          }
        }

        await HapticFeedback.heavyImpact();

        // 0. Pre-Flight Calibration Check
        // Enforce professional hardware baseline before allowing training
        if (mounted) {
          final passedCalibration = await showPreFlightCheck(context);
          if (!passedCalibration) {
            setState(() => isProcessing = false);
            return; // Abort recording if room is too loud or mic fails
          }
        }

        // Clear buffer on start
        setState(() => _amplitudeBuffer.clear());

        // Set controller-level max duration based on reference call
        final selectedCall = ReferenceDatabase.getById(selectedCallId);
        notifier.setMaxDuration(selectedCall.idealDurationSec);

        await notifier.startRecordingWithCountdown();

        final finalState = ref.read(recordingNotifierProvider);
        if (finalState.status == RecordingStatus.error) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Recording Failed: ${finalState.errorMessage}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        } else if (finalState.isRecording) {
          final call = ReferenceDatabase.getById(selectedCallId);
          final autoStopSec = (call.idealDurationSec + 2).clamp(3, 60).toInt();
          _autoStopTimer?.cancel();
          _autoStopTimer = Timer(Duration(seconds: autoStopSec), () {
            if (mounted && ref.read(recordingNotifierProvider).isRecording) {
              _toggleRecording();
            }
          });
        }
      }
    } catch (e, stackTrace) {
      AppLogger.d('Recording toggle error: $e\n$stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // Permission dialogs delegated to recorder_dialogs.dart

  Future<void> _playReferenceSound() async {
    if (isPlayingReference) {
      await _audioPlayer.stop();
      setState(() => isPlayingReference = false);
    } else {
      final selectedCallId = ref.read(selectedCallIdProvider);
      final call = ReferenceDatabase.getById(selectedCallId);
      final cloudAudio = ref.read(cloudAudioServiceProvider);

      try {
        final source = await cloudAudio.resolveAudioSource(call.id, call.audioAssetPath);
        if (source.isAsset) {
          await _audioPlayer.play(AssetSource(source.path));
        } else {
          await _audioPlayer.play(DeviceFileSource(source.path));
        }
        setState(() => isPlayingReference = true);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Could not play audio: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final recordingState = ref.watch(recordingNotifierProvider);
    final selectedCallId = ref.watch(selectedCallIdProvider);
    final isRecording = recordingState.isRecording;
    final isCountingDown = recordingState.isCountingDown;

    final selectedCall = ReferenceDatabase.getById(selectedCallId);

    return BackgroundWrapper(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          title: Text(S.of(context).recordCall,
              style: GoogleFonts.oswald(fontWeight: FontWeight.bold, letterSpacing: 1.5)),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 1. Animal Selection
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Material(
                        color: Colors.transparent,
                        child: Semantics(
                          button: true,
                          label:
                              'Select animal call. Currently selected: ${selectedCall.animalName} ${selectedCall.callType}',
                          child: InkWell(
                            onTap: (isRecording || isCountingDown)
                                ? null
                                : () async {
                                    final newId = await Navigator.push<String>(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) =>
                                              const CategoryGridScreen(selectionMode: true)),
                                    );
                                    if (newId != null && mounted) {
                                      ref.read(selectedCallIdProvider.notifier).setCallId(newId);
                                    }
                                  },
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: AppColors.of(context).border,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppColors.of(context).border),
                              ),
                              child: Row(
                                children: [
                                  ClipOval(
                                    child: Image.asset(
                                      selectedCall.imageUrl,
                                      width: 40,
                                      height: 40,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) => Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: AppColors.of(context).border,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(Icons.photo,
                                            size: 20, color: AppColors.of(context).textSubtle),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          selectedCall.animalName,
                                          style: GoogleFonts.oswald(
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.of(context).textPrimary,
                                            fontSize: 16,
                                          ),
                                        ),
                                        Text(
                                          '${selectedCall.category} • ${selectedCall.callType}',
                                          style: GoogleFonts.lato(
                                              color: AppColors.of(context).textSecondary,
                                              fontSize: 13),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(Icons.chevron_right,
                                      color: AppColors.of(context).textSecondary),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 2. LIVE VISUALIZER + COACHING
                RecorderVisualizerSection(
                  selectedCall: selectedCall,
                  amplitudeBuffer: _amplitudeBuffer,
                  isRecording: isRecording,
                  isCountingDown: isCountingDown,
                  computeRefAvg: _computeRefAvg,
                  getCoachingFeedback: _getCoachingFeedback,
                ),

                const SizedBox(height: 24),

                _buildGlassButton(
                  onPressed:
                      (isRecording || isCountingDown || isProcessing) ? null : _playReferenceSound,
                  icon: isPlayingReference ? Icons.stop_circle_outlined : Icons.volume_up_rounded,
                  label:
                      isPlayingReference ? S.of(context).tapToStop : S.of(context).listenReference,
                ),

                const SizedBox(height: 24),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // ... (Existing controls code similar)
                    // Retry Button
                    if (isRecording || isCountingDown)
                      Padding(
                        padding: const EdgeInsets.only(right: 24.0),
                        child: _buildSmallIconButton(
                          onPressed: _resetRecording,
                          icon: Icons.refresh_rounded,
                          label: S.of(context).resetRecording,
                        ),
                      )
                    else
                      const SizedBox(width: 80),

                    // Mic button with decorative rings
                    Semantics(
                      button: true,
                      label: isRecording ? S.of(context).tapToStop : S.of(context).tapToRecord,
                      child: RecorderMicButton(
                        isRecording: isRecording,
                        isCountingDown: isCountingDown,
                        isProcessing: isProcessing,
                        countdownValue: recordingState.countdownValue ?? 0,
                        pulseAnimation: _pulseAnimation,
                        onPressed: _toggleRecording,
                      ),
                    ),
                    const SizedBox(width: 80),
                  ],
                ),
                const SizedBox(height: 24),
                if (isRecording)
                  RecordingTimerBadge(
                    formattedDuration: _formatDuration(recordingState.recordDuration),
                  ),

                const SizedBox(height: 8),
                // TAP TO RECORD
                TextButton(
                  onPressed: (isCountingDown || isProcessing)
                      ? null
                      : () {
                          _toggleRecording();
                        },
                  child: Text(
                    isCountingDown
                        ? S.of(context).getReady
                        : isRecording
                            ? S.of(context).recordingInProgress
                            : S.of(context).tapToRecord,
                    style: GoogleFonts.oswald(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color:
                          isRecording ? Colors.redAccent.shade100 : Theme.of(context).primaryColor,
                      letterSpacing: 2.0,
                    ),
                  ),
                ),
                if (!isRecording && !isCountingDown && !isProcessing) ...[
                  const SizedBox(height: 6),
                  Text(
                    S.of(context).matchReferenceHint,
                    style: GoogleFonts.lato(
                      fontSize: 12,
                      color: AppColors.of(context).textSubtle,
                    ),
                  ),
                ],
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassButton(
      {required VoidCallback? onPressed, required IconData icon, required String label}) {
    return Semantics(
      button: true,
      label: label,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: TextButton.icon(
            onPressed: onPressed,
            icon: Icon(icon, color: AppColors.of(context).textSecondary, size: 20),
            label: Text(label,
                style: GoogleFonts.lato(
                    color: AppColors.of(context).textPrimary,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2)),
            style: TextButton.styleFrom(
              backgroundColor: AppColors.of(context).cardOverlay,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              side: BorderSide(color: AppColors.of(context).border),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSmallIconButton(
      {required VoidCallback onPressed, required IconData icon, required String label}) {
    return Semantics(
      button: true,
      label: label,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.of(context).border,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.of(context).border),
                ),
                child: IconButton(
                  onPressed: onPressed,
                  icon: Icon(icon, color: AppColors.of(context).textSecondary, size: 20),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.oswald(
              color: Colors.white60,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}
