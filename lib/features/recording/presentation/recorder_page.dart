import 'package:flutter/material.dart';
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
      appBar: AppBar(title: const Text('Record Call')),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animal Selection Dropdown
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: selectedCallId,
                  hint: const Text("Select Call to Practice"),
                  onChanged: isRecording ? null : (String? newValue) {
                    setState(() {
                      selectedCallId = newValue!;
                    });
                  },
                  items: MockReferenceDatabase.calls.map((call) {
                    return DropdownMenuItem<String>(
                      value: call.id,
                      child: Text(call.animalName, style: const TextStyle(fontWeight: FontWeight.w500)),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          TextButton.icon(
            onPressed: isRecording ? null : _playReferenceSound,
            icon: Icon(isPlayingReference ? Icons.stop_circle_outlined : Icons.volume_up_rounded),
            label: Text(isPlayingReference ? "Stop Reference" : "Hear Sample"),
            style: TextButton.styleFrom(foregroundColor: Colors.grey[700]),
          ),
          const SizedBox(height: 20),

          LiveVisualizer(
            amplitudes: amplitudes,
            isRecording: isRecording,
          ),
          const SizedBox(height: 40),
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
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.red.withValues(alpha: 0.5), width: 4),
                      ),
                    ),
                  ),
                // Main Button
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: isRecording ? Colors.red : Colors.green,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: (isRecording ? Colors.red : Colors.green).withValues(alpha: 0.4),
                        blurRadius: 15,
                        spreadRadius: 5,
                      )
                    ],
                  ),
                  child: Icon(
                    isRecording ? Icons.stop : Icons.mic,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            isRecording ? 'Recording...' : 'Tap to Record',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }
}
