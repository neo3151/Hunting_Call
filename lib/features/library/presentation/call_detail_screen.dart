import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:audioplayers/audioplayers.dart';
import '../domain/reference_call_model.dart';
import 'acoustic_spectrum_widget.dart';

class CallDetailScreen extends StatefulWidget {
  final ReferenceCall call;

  const CallDetailScreen({super.key, required this.call});

  @override
  State<CallDetailScreen> createState() => _CallDetailScreenState();
}

class _CallDetailScreenState extends State<CallDetailScreen> with SingleTickerProviderStateMixin {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _togglePlayback() async {
    if (_isPlaying) {
      await _audioPlayer.stop();
      if (mounted) setState(() => _isPlaying = false);
    } else {
      final assetPath = widget.call.audioAssetPath.replaceFirst('assets/', '');
      try {
        await _audioPlayer.play(AssetSource(assetPath));
        if (mounted) setState(() => _isPlaying = true);
        
        _audioPlayer.onPlayerComplete.listen((_) {
          if (mounted) setState(() => _isPlaying = false);
        });
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error playing audio: $e"), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Hero Header
          SliverAppBar(
            expandedHeight: 350,
            pinned: true,
            stretch: true,
            backgroundColor: const Color(0xFF1B5E20),
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                widget.call.callType.toUpperCase(),
                style: GoogleFonts.oswald(fontWeight: FontWeight.bold, letterSpacing: 2),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    widget.call.imageUrl,
                    fit: BoxFit.cover,
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Color(0xFF121212)],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Names Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.call.animalName,
                            style: GoogleFonts.oswald(fontSize: 32, color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            widget.call.scientificName,
                            style: const TextStyle(color: Colors.white54, fontSize: 16, fontStyle: FontStyle.italic),
                          ),
                        ],
                      ),
                      _buildDifficultyBadge(widget.call.difficulty),
                    ],
                  ),
                  
                  const SizedBox(height: 30),
                  
                  // Action Row
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _togglePlayback,
                          icon: Icon(_isPlaying ? Icons.stop_rounded : Icons.play_arrow_rounded),
                          label: Text(_isPlaying ? "STOP REFERENCE" : "LISTEN TO REFERENCE"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF81C784),
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          onPressed: () {
                            // Link to Practice Screen (to be implemented)
                            Navigator.pop(context, 'PRACTICE'); 
                          },
                          icon: const Icon(Icons.mic, color: Colors.white70),
                          tooltip: "Start Practice",
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // Bioacoustic Data Section
                  _sectionHeader("ACOUSTIC SIGNATURE"),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _metricCard("DOMINANT PITCH", "${widget.call.idealPitchHz.toInt()} Hz", Icons.graphic_eq),
                      const SizedBox(width: 12),
                      _metricCard("DURATION", "${widget.call.idealDurationSec} Sec", Icons.timer_outlined),
                    ],
                  ),
                  const SizedBox(height: 16),
                  AcousticSpectrumWidget(
                    pitchHz: widget.call.idealPitchHz,
                    durationSec: widget.call.idealDurationSec,
                  ),
                  
                  const SizedBox(height: 30),
                  
                  // Description
                  _sectionHeader("NATURAL HISTORY"),
                  const SizedBox(height: 12),
                  Text(
                    widget.call.description,
                    style: const TextStyle(color: Colors.white70, fontSize: 16, height: 1.6),
                  ),
                  
                  const SizedBox(height: 30),
                  
                  // Pro Tips Card
                  if (widget.call.proTips.isNotEmpty) _buildProTipsCard(),
                  
                  const SizedBox(height: 50),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.oswald(color: const Color(0xFF81C784), fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.2),
    );
  }

  Widget _metricCard(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.white38, size: 20),
            const SizedBox(height: 12),
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            Text(label, style: const TextStyle(color: Colors.white38, fontSize: 10)),
          ],
        ),
      ),
    );
  }

  Widget _buildProTipsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF81C784).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF81C784).withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.tips_and_updates_rounded, color: Color(0xFF81C784)),
              const SizedBox(width: 12),
              Text(
                "FIELD PRO TIPS",
                style: GoogleFonts.oswald(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            widget.call.proTips,
            style: const TextStyle(color: Colors.white70, fontSize: 15, height: 1.5),
          ),
        ],
      ),
    );
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        difficulty.toUpperCase(),
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }
}
