import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../../providers/providers.dart';
import '../../rating/presentation/rating_screen.dart';
import '../../library/data/mock_reference_database.dart';
import 'widgets/live_visualizer.dart';

class RecorderPage extends ConsumerStatefulWidget {
  final String userId;
  const RecorderPage({super.key, required this.userId});

  @override
  ConsumerState<RecorderPage> createState() => _RecorderPageState();
}

class _RecorderPageState extends ConsumerState<RecorderPage> with SingleTickerProviderStateMixin {
  String selectedCallId = MockReferenceDatabase.calls.first.id;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool isPlayingReference = false;
  StreamSubscription? _playerCompleteSubscription;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(_pulseController);

    // Initialize recorder via provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(recordingNotifierProvider.notifier).initialize();
    });
    
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

  void _toggleRecording() async {
    final notifier = ref.read(recordingNotifierProvider.notifier);
    final status = ref.read(recordingNotifierProvider).status;

    if (status == RecordingStatus.recording) {
      final path = await notifier.stopRecording();
      
      if (mounted) {
        if (path != null && path.isNotEmpty && !path.contains("not open")) {
           Navigator.of(context).pushReplacement(
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
    } else {
      final success = await notifier.startRecording();
      if (!success) {
         final error = ref.read(recordingNotifierProvider).error ?? "Unknown Error";
         if (!mounted) return;
         ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(
               content: Text("Recording Failed: $error"),
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
      final call = MockReferenceDatabase.getById(selectedCallId);
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
    final isRecording = recordingState.status == RecordingStatus.recording;
    
    // Listen to amplitude changes to update the visualizer via the notifier
    ref.listen(amplitudeStreamProvider, (previous, next) {
      next.whenData((amplitude) {
        ref.read(recordingNotifierProvider.notifier).updateAmplitudes(amplitude);
      });
    });

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('RECORD CALL', style: GoogleFonts.oswald(fontWeight: FontWeight.bold, letterSpacing: 1.5)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/forest_background.png'),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(Colors.black54, BlendMode.darken),
          ),
        ),
        child: SafeArea(
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
                          onChanged: isRecording ? null : (String? newValue) {
                            setState(() {
                              selectedCallId = newValue!;
                            });
                          },
                          items: MockReferenceDatabase.calls.map((call) {
                            final parts = _parseCallName(call.animalName);
                            return DropdownMenuItem<String>(
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
                                          parts['animal']!,
                                          style: GoogleFonts.oswald(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                            fontSize: 14,
                                          ),
                                        ),
                                        if (parts['callType']!.isNotEmpty)
                                          Text(
                                            parts['callType']!,
                                            style: GoogleFonts.lato(
                                              color: Colors.white70,
                                              fontSize: 11,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      "${call.idealPitchHz.toInt()} Hz",
                                      style: GoogleFonts.lato(
                                        color: Colors.white70,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              _buildGlassButton(
                onPressed: isRecording ? null : _playReferenceSound,
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
                onTap: _toggleRecording,
                child: Stack(
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
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        color: isRecording ? Colors.red.withValues(alpha: 0.8) : Colors.green.withValues(alpha: 0.8),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: (isRecording ? Colors.red : Colors.green).withValues(alpha: 0.4),
                            blurRadius: 20,
                            spreadRadius: 5,
                          )
                        ],
                        border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 2),
                      ),
                      child: Icon(
                        isRecording ? Icons.stop : Icons.mic,
                        color: Colors.white,
                        size: 36,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                isRecording ? 'RECORDING IN PROGRESS...' : 'READY TO RECORD',
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

  Map<String, String> _parseCallName(String fullName) {
    if (fullName.contains('(') && fullName.contains(')')) {
      final parts = fullName.split('(');
      return {
        'animal': parts[0].trim(),
        'callType': parts[1].replaceAll(')', '').trim(),
      };
    } else if (fullName.contains('-')) {
      final parts = fullName.split('-');
      return {
        'animal': parts[0].trim(),
        'callType': parts.length > 1 ? parts[1].trim() : '',
      };
    }
    return {
      'animal': fullName,
      'callType': '',
    };
  }

  String _getAnimalEmoji(String animalName) {
    final lower = animalName.toLowerCase();
    if (lower.contains('duck') || lower.contains('mallard')) return '🦆';
    if (lower.contains('elk')) return '🦌';
    if (lower.contains('deer') || lower.contains('whitetail')) return '🦌';
    if (lower.contains('turkey')) return '🦃';
    if (lower.contains('coyote')) return '🐺';
    if (lower.contains('goose')) return '🪿';
    if (lower.contains('owl')) return '🦉';
    if (lower.contains('moose')) return '🫎';
    return '🦌';
  }
}
