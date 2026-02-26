import 'dart:async';
import 'dart:io' show Platform;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:outcall/features/profile/presentation/controllers/profile_controller.dart';
import 'package:outcall/features/recording/presentation/controllers/recording_controller.dart';
import 'package:outcall/core/widgets/background_wrapper.dart';
import 'package:outcall/features/rating/presentation/rating_screen.dart';
import 'package:outcall/features/library/data/reference_database.dart';

import 'package:outcall/core/services/cloud_audio_service.dart';
import 'package:outcall/features/recording/presentation/widgets/live_visualizer.dart';
import 'package:outcall/features/recording/domain/visualization_settings.dart';
import 'package:outcall/features/recording/presentation/call_selection_screen.dart';
import 'package:outcall/core/utils/app_logger.dart';
import 'package:outcall/features/recording/presentation/widgets/recorder_widgets.dart';

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
  StreamSubscription<double>? _amplitudeSubscription;

  @override
  void initState() {
    super.initState();
    
    // Initialize selected call
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.preselectedAnimalId != null) {
        ref.read(selectedCallIdProvider.notifier).state = widget.preselectedAnimalId!;
      } else {
        final isPremium = ref.read(profileNotifierProvider).profile?.isPremium ?? false;
        final availableCalls = ReferenceDatabase.calls.where((c) => !ReferenceDatabase.isLocked(c.id, isPremium)).toList();
        
        if (availableCalls.isNotEmpty) {
           ref.read(selectedCallIdProvider.notifier).state = availableCalls.first.id;
        } else {
           ref.read(selectedCallIdProvider.notifier).state = ReferenceDatabase.calls.first.id;
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
    // ignore: deprecated_member_use
    _amplitudeSubscription = ref.read(amplitudeStreamProvider.stream).listen((amp) {
      if (mounted) {
        setState(() {
          _amplitudeBuffer.add(amp);
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
    _amplitudeSubscription?.cancel();
    _audioPlayer.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  String _formatDuration(int seconds) {
    final int minutes = seconds ~/ 60;
    final int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  /// Compute average amplitude from reference waveform for coaching zone
  double _computeRefAvg(List<double>? waveform) {
    if (waveform == null || waveform.isEmpty) return 0.0;
    double sum = 0;
    int count = 0;
    for (final v in waveform) {
      if (v > 0.05) {
        sum += v;
        count++;
      }
    }
    return count > 0 ? sum / count : 0.0;
  }

  /// Get coaching feedback based on current amplitude vs reference target
  ({String text, Color color}) _getCoachingFeedback(double refAvg) {
    if (_amplitudeBuffer.isEmpty || refAvg < 0.05) {
      return (text: '', color: Colors.transparent);
    }
    // Use the average of last 10 samples for stable feedback
    final recent = _amplitudeBuffer.length > 10
        ? _amplitudeBuffer.sublist(_amplitudeBuffer.length - 10)
        : _amplitudeBuffer;
    final currentAvg = recent.fold<double>(0.0, (a, b) => a + b) / recent.length;
    
    if (currentAvg < 0.02) return (text: '', color: Colors.transparent); // Silence
    
    final zoneLow = refAvg * 0.5;
    final zoneHigh = refAvg * 1.5;
    
    if (currentAvg >= zoneLow && currentAvg <= zoneHigh) {
      return (text: '🎯 IN RANGE', color: const Color(0xFF5FF7B6));
    } else if (currentAvg < zoneLow) {
      return (text: '🔇 TOO QUIET', color: const Color(0xFFFFD54F));
    } else {
      return (text: '📢 TOO LOUD', color: const Color(0xFFFF5252));
    }
  }

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
                Navigator.of(context).push(
                   MaterialPageRoute(builder: (_) => RatingScreen(
                     audioPath: path, 
                     animalId: selectedCallId,
                     userId: widget.userId,
                   ))
                );
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
              if (mounted) _showPermissionDeniedDialog();
              return;
            }
          } else if (permissionStatus.isPermanentlyDenied) {
            if (mounted) _showPermissionSettingsDialog();
            return;
          }
        }
        
        await HapticFeedback.heavyImpact();
        
        // Clear buffer on start
        setState(() => _amplitudeBuffer.clear());

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

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: Row(
          children: [
            const Icon(Icons.mic_off, color: Colors.orangeAccent),
            const SizedBox(width: 12),
            Text('Microphone Access', style: GoogleFonts.oswald(color: Colors.white)),
          ],
        ),
        content: const Text(
          'We need microphone access to record your hunting calls. This helps us analyze your technique and provide scoring.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Not Now', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final granted = await Permission.microphone.request();
              if (granted.isGranted) {
                _toggleRecording();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: const Color(0xFF121212),
            ),
            child: const Text('Allow'),
          ),
        ],
      ),
    );
  }

  void _showPermissionSettingsDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: Row(
          children: [
            const Icon(Icons.settings, color: Colors.orangeAccent),
            const SizedBox(width: 12),
            Text('Permission Required', style: GoogleFonts.oswald(color: Colors.white)),
          ],
        ),
        content: const Text(
          'Microphone access is disabled in system settings. Please enable it to record hunting calls.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              await openAppSettings();
              if (mounted) navigator.pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: const Color(0xFF121212),
            ),
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }


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
           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not play audio: $e')));
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
    
    // New: Watch visualization settings
    final vizSettings = ref.watch(visualizationSettingsProvider);
    final selectedCall = ReferenceDatabase.getById(selectedCallId);

    return BackgroundWrapper(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          title: Text('RECORD CALL', style: GoogleFonts.oswald(fontWeight: FontWeight.bold, letterSpacing: 1.5)),
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
                      child: InkWell(
                        onTap: (isRecording || isCountingDown) ? null : () async {
                          final newId = await Navigator.push<String>(
                            context,
                            MaterialPageRoute(builder: (_) => const CallSelectionScreen()),
                          );
                          if (newId != null && mounted) {
                            ref.read(selectedCallIdProvider.notifier).state = newId;
                          }
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
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
                                      color: Colors.white.withValues(alpha: 0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.photo, size: 20, color: Colors.white38),
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
                                        color: Colors.white,
                                        fontSize: 16,
                                      ),
                                    ),
                                    Text(
                                      '${selectedCall.category} • ${selectedCall.callType}',
                                      style: GoogleFonts.lato(color: Colors.white70, fontSize: 13),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_right, color: Colors.white70),
                            ],
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
                onPressed: (isRecording || isCountingDown || isProcessing) ? null : _playReferenceSound,
                icon: isPlayingReference ? Icons.stop_circle_outlined : Icons.volume_up_rounded,
                label: isPlayingReference ? 'STOP REFERENCE' : 'HEAR SAMPLE',
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
                        label: 'RESET',
                      ),
                    )
                  else
                    const SizedBox(width: 80),

                  // Mic button with decorative rings
                  RecorderMicButton(
                    isRecording: isRecording,
                    isCountingDown: isCountingDown,
                    isProcessing: isProcessing,
                    countdownValue: recordingState.countdownValue ?? 0,
                    pulseAnimation: _pulseAnimation,
                    onPressed: _toggleRecording,
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
                onPressed: (isCountingDown || isProcessing) ? null : () {
                  _toggleRecording();
                },
                child: Text(
                  isCountingDown 
                      ? 'GET READY...' 
                      : isRecording 
                          ? 'RECORDING IN PROGRESS' 
                          : 'TAP TO RECORD',
                  style: GoogleFonts.oswald(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isRecording ? Colors.redAccent.shade100 : Theme.of(context).primaryColor,
                    letterSpacing: 2.0,
                  ),
                ),
              ),
              if (!isRecording && !isCountingDown && !isProcessing) ...[
                const SizedBox(height: 6),
                Text(
                  'Match the reference call above to improve your score',
                  style: GoogleFonts.lato(
                    fontSize: 12,
                    color: Colors.white38,
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

  Widget _buildGlassButton({required VoidCallback? onPressed, required IconData icon, required String label}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: TextButton.icon(
          onPressed: onPressed,
          icon: Icon(icon, color: Colors.white70, size: 20),
          label: Text(label, style: GoogleFonts.lato(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
          style: TextButton.styleFrom(
            backgroundColor: Colors.white.withValues(alpha: 0.05),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
          ),
        ),
      ),
    );
  }


  Widget _buildSmallIconButton({required VoidCallback onPressed, required IconData icon, required String label}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: IconButton(
                onPressed: onPressed,
                icon: Icon(icon, color: Colors.white70, size: 20),
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
    );
  }
}
