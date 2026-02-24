import 'dart:async';
import 'dart:io' show Platform;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:hunting_calls_perfection/features/profile/presentation/controllers/profile_controller.dart';
import 'package:hunting_calls_perfection/features/recording/presentation/controllers/recording_controller.dart';
import 'package:hunting_calls_perfection/core/widgets/background_wrapper.dart';
import 'package:hunting_calls_perfection/features/rating/presentation/rating_screen.dart';
import 'package:hunting_calls_perfection/features/library/data/reference_database.dart';
import 'package:hunting_calls_perfection/features/library/domain/reference_call_model.dart';
import 'package:hunting_calls_perfection/core/services/cloud_audio_service.dart';
import 'package:hunting_calls_perfection/features/recording/presentation/widgets/live_visualizer.dart';
import 'package:hunting_calls_perfection/features/recording/domain/visualization_settings.dart';

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
    
    debugPrint('🎙️ _toggleRecording called!');
    
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
        
        debugPrint('🎙️ Starting recording with countdown...');
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
      debugPrint('🔴 _toggleRecording error: $e');
      debugPrint('🔴 Stack trace: $stackTrace');
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
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: selectedCallId,
                          dropdownColor: const Color(0xFF1A1A1A),
                          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white70),
                          hint: Text('Select Call to Practice', style: GoogleFonts.lato(color: Colors.white70)),
                          onChanged: (isRecording || isCountingDown) ? null : (String? newValue) {
                            if (newValue != null && !newValue.startsWith('header_')) {
                              ref.read(selectedCallIdProvider.notifier).state = newValue;
                            }
                          },
                          items: _buildDropdownItems(isRecording || isCountingDown),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // 2. LIVE VISUALIZER
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Container(
                    height: 140,
                    decoration: BoxDecoration(
                        color: Colors.black26, 
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white10),
                    ),
                    child: Stack(
                        children: [
                            // Optimized: Use StreamBuilder for high-frequency updates
                            // This ensures only the visualizer rebuilds, not the whole page.
                            StreamBuilder<double>(
                              stream: ref.watch(amplitudeStreamProvider).whenData((v) => v).asData != null
                                // ignore: deprecated_member_use
                                ? ref.watch(amplitudeStreamProvider.stream)
                                : const Stream<double>.empty(),
                              builder: (context, snapshot) {
                                // Update local buffer
                                if (snapshot.hasData) {
                                  _amplitudeBuffer.add(snapshot.data!);
                                  if (_amplitudeBuffer.length > 100) {
                                      _amplitudeBuffer.removeAt(0);
                                  }
                                }
                                
                                return LiveVisualizer(
                                    amplitudes: List<double>.from(_amplitudeBuffer), // Create copy to force repaint
                                    referencePattern: vizSettings.showReferenceOverlay ? selectedCall.waveform : null,
                                    referenceSpectrogram: vizSettings.showReferenceOverlay ? selectedCall.spectrogram : null,
                                    mode: vizSettings.mode,
                                    color: (isRecording || isCountingDown) ? Colors.tealAccent : Colors.teal.withValues(alpha: 0.5),
                                    isRecording: isRecording || isCountingDown,
                                    referenceAvgAmplitude: _computeRefAvg(selectedCall.waveform),
                                );
                              }
                            ),
                            
                            // Mode Toggles Overlay (Top Right)
                            Positioned(
                                top: 4,
                                right: 4,
                                child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                        // Mode Toggle
                                        IconButton(
                                            onPressed: () => ref.read(visualizationSettingsProvider.notifier).toggleMode(),
                                            icon: Icon(
                                                vizSettings.mode == VisualizationMode.waveform ? Icons.graphic_eq : Icons.bar_chart, 
                                                color: Colors.white54, 
                                                size: 18
                                            ),
                                            tooltip: 'Switch View',
                                        ),
                                        // Reference Overlay Toggle
                                        IconButton(
                                            onPressed: () => ref.read(visualizationSettingsProvider.notifier).toggleReferenceOverlay(),
                                            icon: Icon(
                                                Icons.layers, 
                                                color: vizSettings.showReferenceOverlay ? Colors.orangeAccent : Colors.white54, 
                                                size: 18
                                            ),
                                            tooltip: 'Toggle Reference',
                                        ),
                                    ],
                                ),
                            ),
                            // Label Overlay (Top Left)
                            Positioned(
                                top: 8,
                                left: 12,
                                child: Text(
                                    vizSettings.mode == VisualizationMode.waveform ? 'WAVEFORM' : 'SPECTRAL SYNC',
                                    style: GoogleFonts.oswald(color: Colors.white24, fontSize: 10, letterSpacing: 1),
                                ),
                            ),
                        ],
                    ),
                ),
              ),
              // Coaching Text Indicator
              if (isRecording) Builder(
                builder: (context) {
                  final refAvg = _computeRefAvg(selectedCall.waveform);
                  final feedback = _getCoachingFeedback(refAvg);
                  if (feedback.text.isEmpty) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 200),
                      style: GoogleFonts.oswald(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2.0,
                        color: feedback.color,
                      ),
                      child: Text(feedback.text),
                    ),
                  );
                },
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
                  SizedBox(
                    width: 150,
                    height: 150,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Outer decorative ring
                        if (!isRecording && !isCountingDown && !isProcessing)
                          Container(
                            width: 150,
                            height: 150,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Theme.of(context).primaryColor.withValues(alpha: 0.15),
                                width: 2,
                              ),
                            ),
                          ),
                        // Inner decorative ring
                        if (!isRecording && !isCountingDown && !isProcessing)
                          Container(
                            width: 125,
                            height: 125,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Theme.of(context).primaryColor.withValues(alpha: 0.25),
                                width: 2,
                              ),
                            ),
                          ),
                        if (isRecording)
                          ScaleTransition(
                            scale: _pulseAnimation,
                            child: Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.red.withValues(alpha: 0.3), width: 4),
                              ),
                            ),
                          ),
                        if (isCountingDown)
                          Container(
                            width: 150,
                            height: 150,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.orange.withValues(alpha: 0.5), width: 3),
                            ),
                          ),
                        // THE ACTUAL BUTTON
                        SizedBox(
                          width: 90,
                          height: 90,
                          child: ElevatedButton(
                            onPressed: (isCountingDown || isProcessing) ? null : () {
                              debugPrint('🎙️ RECORD BUTTON PRESSED!');
                              _toggleRecording();
                            },
                            style: ElevatedButton.styleFrom(
                              shape: const CircleBorder(),
                              padding: EdgeInsets.zero,
                              backgroundColor: isProcessing
                                  ? Colors.grey.withValues(alpha: 0.8)
                                  : isRecording 
                                      ? Colors.red.withValues(alpha: 0.8) 
                                      : isCountingDown 
                                          ? Colors.orange.withValues(alpha: 0.8)
                                          : Theme.of(context).primaryColor,
                              elevation: 8,
                              shadowColor: (isProcessing ? Colors.grey : isRecording ? Colors.red : Theme.of(context).primaryColor).withValues(alpha: 0.4),
                              side: BorderSide(color: Colors.white.withValues(alpha: 0.2), width: 2),
                            ),
                            child: isProcessing
                                ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 3)
                                : isCountingDown
                                    ? Text(
                                        '${recordingState.countdownValue}',
                                        style: GoogleFonts.oswald(
                                          fontSize: 48,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Icon(
                                        isRecording ? Icons.stop : Icons.mic,
                                        color: Colors.white,
                                        size: 36,
                                      ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 80),
                ],
              ),
              const SizedBox(height: 24),
              if (isRecording)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.circle, color: Colors.red, size: 12),
                      const SizedBox(width: 8),
                      Text(
                        _formatDuration(recordingState.recordDuration),
                        style: GoogleFonts.oswald(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 8),
              // TAP TO RECORD
              TextButton(
                onPressed: (isCountingDown || isProcessing) ? null : () {
                  debugPrint('🎙️ TEXT BUTTON PRESSED!');
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

  List<DropdownMenuItem<String>> _buildDropdownItems(bool isDisabled) {
    final items = <DropdownMenuItem<String>>[];
    final groups = <String, List<ReferenceCall>>{};
    
    final isPremium = ref.read(profileNotifierProvider).profile?.isPremium ?? false;
    
    // Group calls by category (only if not locked)
    for (final call in ReferenceDatabase.calls) {
      if (!ReferenceDatabase.isLocked(call.id, isPremium)) {
        groups.putIfAbsent(call.category, () => []).add(call);
      }
    }
    
    // Sort categories (Waterfowl first, etc)
    final sortedCategories = groups.keys.toList()..sort();
    
    for (final category in sortedCategories) {
      // Category Header (Divider)
      items.add(
        DropdownMenuItem<String>(
          enabled: false,
          value: 'header_$category',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (items.isNotEmpty)
                const Divider(color: Colors.white10, height: 1),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  children: [
                    Icon(_getCategoryIcon(category), color: Theme.of(context).primaryColor, size: 14),
                    const SizedBox(width: 8),
                    Text(
                      category.toUpperCase(),
                      style: GoogleFonts.oswald(
                        color: Theme.of(context).primaryColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
      
      // Calls in this category
      for (final call in groups[category]!) {
        items.add(
          DropdownMenuItem<String>(
            value: call.id,
            child: Row(
              children: [
                ClipOval(
                  child: Semantics(
                    label: 'Target animal: ${call.animalName}',
                    image: true,
                    child: Image.asset(
                      call.imageUrl,
                      width: 32,
                      height: 32,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.photo, size: 16, color: Colors.white38),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        call.animalName,
                        style: GoogleFonts.oswald(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        call.callType,
                        style: GoogleFonts.lato(
                          color: Colors.white70,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildDifficultyBadge(call.difficulty),
              ],
            ),
          ),
        );
      }
    }
    return items;
  }

  Widget _buildDifficultyBadge(String difficulty) {
    Color color;
    switch (difficulty.toLowerCase()) {
      case 'easy': color = Theme.of(context).primaryColor; break;
      case 'intermediate': color = const Color(0xFFFFB74D); break;
      case 'pro': color = const Color(0xFFE57373); break;
      default: color = Colors.white54;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        difficulty.substring(0, 1).toUpperCase(),
        style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'waterfowl': return Icons.water;
      case 'big game': return Icons.landscape;
      case 'predators': return Icons.security;
      case 'land birds': return Icons.forest;
      default: return Icons.category;
    }
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
