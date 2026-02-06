import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../../providers/providers.dart';
import '../../../core/widgets/background_wrapper.dart';
import '../../rating/presentation/rating_screen.dart';
import '../../library/data/reference_database.dart';
import '../../library/domain/reference_call_model.dart';
import 'widgets/live_visualizer.dart';

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

  @override
  void initState() {
    super.initState();
    
    // Initialize selected call
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.preselectedAnimalId != null) {
        ref.read(selectedCallIdProvider.notifier).state = widget.preselectedAnimalId!;
      } else {
        ref.read(selectedCallIdProvider.notifier).state = ReferenceDatabase.calls.first.id;
      }
      ref.read(recordingNotifierProvider.notifier).initialize();
    });
    
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(_pulseController);

    _playerCompleteSubscription = _audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) setState(() => isPlayingReference = false);
    });
  }

  @override
  void dispose() {
    _playerCompleteSubscription?.cancel();
    _audioPlayer.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  String _formatDuration(int seconds) {
    final int minutes = seconds ~/ 60;
    final int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  bool isProcessing = false;

  void _resetRecording() async {
    if (isProcessing) return;
    await HapticFeedback.selectionClick();
    ref.read(recordingNotifierProvider.notifier).reset();
  }

  void _toggleRecording() async {
    if (isProcessing) return;
    
    final notifier = ref.read(recordingNotifierProvider.notifier);
    final recordingState = ref.read(recordingNotifierProvider);
    final selectedCallId = ref.read(selectedCallIdProvider);

    if (recordingState.isRecording) {
      setState(() => isProcessing = true);
      await HapticFeedback.mediumImpact();
      
      try {
        final path = await notifier.stopRecording();
        
        if (mounted) {
          if (path != null && path.isNotEmpty && !path.contains("not open")) {
              Navigator.of(context).push(
                 MaterialPageRoute(builder: (_) => RatingScreen(
                   audioPath: path, 
                   animalId: selectedCallId,
                   userId: widget.userId,
                 ))
              );
          } else {
             ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Recording Failed: Could not save audio file.")),
             );
          }
        }
      } finally {
        if (mounted) setState(() => isProcessing = false);
      }
    } else {
      await HapticFeedback.heavyImpact();
      await notifier.startRecordingWithCountdown();
      
      final finalState = ref.read(recordingNotifierProvider);
      if (finalState.status == RecordingStatus.error) {
         if (!mounted) return;
         ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(
               content: Text("Recording Failed: ${finalState.error}"),
               backgroundColor: Colors.red,
               duration: const Duration(seconds: 5),
             ),
         );
      }
    }
  }


  Future<void> _playReferenceSound() async {
    if (isPlayingReference) {
      await _audioPlayer.stop();
      setState(() => isPlayingReference = false);
    } else {
      final selectedCallId = ref.read(selectedCallIdProvider);
      final call = ReferenceDatabase.getById(selectedCallId);
      final assetPath = call.audioAssetPath.replaceFirst('assets/', '');
      
      try {
        await _audioPlayer.play(AssetSource(assetPath));
        setState(() => isPlayingReference = true);
      } catch (e) {
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Could not play audio: $e")));
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
    
    // Listen to amplitude changes to update the visualizer via the notifier
    ref.listen(amplitudeStreamProvider, (previous, next) {
      next.whenData((amplitude) {
        ref.read(recordingNotifierProvider.notifier).updateAmplitudes(amplitude);
      });
    });

    return BackgroundWrapper(
      child: Scaffold(
        backgroundColor: Colors.transparent, // Important for BackgroundWrapper
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          title: Text('RECORD CALL', style: GoogleFonts.oswald(fontWeight: FontWeight.bold, letterSpacing: 1.5)),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animal Selection Card (Glassmorphism)
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
                          dropdownColor: const Color(0xFF1B3B24),
                          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white70),
                          hint: Text("Select Call to Practice", style: GoogleFonts.lato(color: Colors.white70)),
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
              const SizedBox(height: 24),
              
              _buildGlassButton(
                onPressed: (isRecording || isCountingDown || isProcessing) ? null : _playReferenceSound,
                icon: isPlayingReference ? Icons.stop_circle_outlined : Icons.volume_up_rounded,
                label: isPlayingReference ? "STOP REFERENCE" : "HEAR SAMPLE",
              ),
              
              const Spacer(),

              LiveVisualizer(
                amplitudes: recordingState.amplitudes,
                isRecording: isRecording,
              ),
              
              const Spacer(),
              
              GestureDetector(
                onTap: (isCountingDown || isProcessing) ? null : _toggleRecording,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Retry Button
                    if (isRecording || isCountingDown || recordingState.amplitudes.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(right: 24.0),
                        child: _buildSmallIconButton(
                          onPressed: _resetRecording,
                          icon: Icons.refresh_rounded,
                          label: "RESET",
                        ),
                      )
                    else
                      const SizedBox(width: 80), // Placeholder to keep main button centered

                    Stack(
                      alignment: Alignment.center,
                      children: [
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
                        Container(
                          width: 90,
                          height: 90,
                          decoration: BoxDecoration(
                            color: isProcessing
                                ? Colors.grey.withValues(alpha: 0.8)
                                : isRecording 
                                    ? Colors.red.withValues(alpha: 0.8) 
                                    : isCountingDown 
                                        ? Colors.orange.withValues(alpha: 0.8)
                                        : Colors.green.withValues(alpha: 0.8),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: (isProcessing ? Colors.grey : isRecording ? Colors.red : isCountingDown ? Colors.orange : Colors.green).withValues(alpha: 0.4),
                                blurRadius: 20,
                                spreadRadius: 5,
                              )
                            ],
                            border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 2),
                          ),
                          child: isProcessing
                              ? const Center(child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                              : isCountingDown
                                  ? Center(
                                      child: Text(
                                        '${recordingState.countdownValue}',
                                        style: GoogleFonts.oswald(
                                          fontSize: 48,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    )
                                  : Icon(
                                      isRecording ? Icons.stop : Icons.mic,
                                      color: Colors.white,
                                      size: 36,
                                    ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 80), // Balancing placeholder
                  ],
                ),
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
              Text(
                isCountingDown 
                    ? 'GET READY...' 
                    : isRecording 
                        ? 'RECORDING IN PROGRESS' 
                        : 'READY TO RECORD',
                style: GoogleFonts.oswald(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isRecording ? Colors.redAccent.shade100 : Colors.white70,
                  letterSpacing: 2.0,
                ),
              ),
              const SizedBox(height: 40),
            ],
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
    
    // Group calls by category (only if not locked)
    for (final call in ReferenceDatabase.calls) {
      if (!call.isLocked) {
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
                    Icon(_getCategoryIcon(category), color: const Color(0xFF81C784), size: 14),
                    const SizedBox(width: 8),
                    Text(
                      category.toUpperCase(),
                      style: GoogleFonts.oswald(
                        color: const Color(0xFF81C784),
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
                Text(
                  _getAnimalEmoji(call.animalName),
                  style: const TextStyle(fontSize: 20),
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
      case 'easy': color = const Color(0xFF81C784); break;
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

  String _getAnimalEmoji(String animalName) {
    final lower = animalName.toLowerCase();
    if (lower.contains('duck') || lower.contains('mallard') || lower.contains('teal') || lower.contains('pintail') || lower.contains('canvasback')) return '🦆';
    if (lower.contains('elk')) return '🦌';
    if (lower.contains('deer') || lower.contains('whitetail') || lower.contains('mule') || lower.contains('fallow') || lower.contains('caribou') || lower.contains('pronghorn') || lower.contains('red stag')) return '🦌';
    if (lower.contains('turkey')) return '🦃';
    if (lower.contains('coyote') || lower.contains('wolf')) return '🐺';
    if (lower.contains('goose')) return '🦆'; 
    if (lower.contains('owl')) return '🦉';
    if (lower.contains('moose')) return '🦌';
    if (lower.contains('bear')) return '🐻';
    if (lower.contains('fox')) return '🦊';
    if (lower.contains('bobcat') || lower.contains('cougar') || lower.contains('mountain lion')) return '🐆';
    if (lower.contains('rabbit')) return '🐰';
    if (lower.contains('raccoon')) return '🦝';
    if (lower.contains('crow')) return '🐦‍⬛';
    if (lower.contains('quail') || lower.contains('pheasant') || lower.contains('woodcock') || lower.contains('dove') || lower.contains('grouse')) return '🐦';
    if (lower.contains('hog')) return '🐗';
    if (lower.contains('badger')) return '🦡';
    return '🦌';
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
