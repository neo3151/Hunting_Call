import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../../../injection_container.dart';
import '../domain/audio_recorder_service.dart';
import '../../rating/presentation/rating_screen.dart';
import '../../library/data/mock_reference_database.dart';
import 'widgets/live_visualizer.dart';

class RecorderPage extends StatefulWidget {
  final String userId;
  const RecorderPage({super.key, required this.userId});

  @override
  State<RecorderPage> createState() => _RecorderPageState();
}

class _RecorderPageState extends State<RecorderPage> with SingleTickerProviderStateMixin {
  final recorder = sl<AudioRecorderService>();
  bool isRecording = false;
  List<double> amplitudes = [];
  String selectedCallId = MockReferenceDatabase.calls.first.id;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool isPlayingReference = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(_pulseController);

    recorder.init();
    recorder.onAmplitudeChanged.listen((amp) {
      if (mounted) {
        setState(() {
          amplitudes.add(amp);
          if (amplitudes.length > 50) amplitudes.removeAt(0);
        });
      }
    });
    
    _audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) setState(() => isPlayingReference = false);
    });
  }

  @override
  void dispose() {
    // BUG FIX: Do NOT dispose the singleton service here. It kills the stream controller for future visits.
    // Instead, just ensure recording is stopped.
    if (isRecording) {
      recorder.stopRecorder(); 
    }
    _audioPlayer.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _toggleRecording() async {
    if (isRecording) {
      final path = await recorder.stopRecorder();
      setState(() => isRecording = false);
      
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
      final success = await recorder.startRecorder('temp_path'); 
      if (success) {
         setState(() => isRecording = true);
      } else {
         final error = recorder.lastError ?? "Unknown Error";
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
      // Remove 'assets/' prefix if AudioCache logic confusingly adds it, 
      // but modern audioplayers uses AssetSource which takes full path usually sans 'assets/'.
      // Wait, AssetSource behavior: "Prefixes the path with 'assets/'".
      // Let's strip 'assets/' from our model-stored path.
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
                            return DropdownMenuItem<String>(
                              value: call.id,
                              child: Text(
                                call.animalName.toUpperCase(), 
                                style: GoogleFonts.oswald(fontWeight: FontWeight.w500, color: Colors.white)
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
              
              // Sample Playback Button
              _buildGlassButton(
                onPressed: isRecording ? null : _playReferenceSound,
                icon: isPlayingReference ? Icons.stop_circle_outlined : Icons.volume_up_rounded,
                label: isPlayingReference ? "STOP REFERENCE" : "HEAR SAMPLE",
              ),
              
              const Spacer(),

              LiveVisualizer(
                amplitudes: amplitudes,
                isRecording: isRecording,
              ),
              
              const Spacer(),
              
              GestureDetector(
                onTap: _toggleRecording,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Pulsing Ring
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
                    // Main Button
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
}
