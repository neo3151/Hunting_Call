import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../library/data/reference_database.dart';
import '../../library/domain/reference_call_model.dart';
import 'call_detail_screen.dart';

class LibraryScreen extends ConsumerStatefulWidget {
  final String? userId;
  const LibraryScreen({super.key, this.userId});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _currentlyPlayingId;
  String _searchQuery = "";
  final List<String> _categories = ["All", "Waterfowl", "Big Game", "Predators", "Land Birds"];

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _togglePlayback(ReferenceCall call) async {
    if (call.isLocked) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Coming Soon! This call will be available in the next update."),
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }
    
    if (_currentlyPlayingId == call.id) {
      await _audioPlayer.stop();
      setState(() => _currentlyPlayingId = null);
    } else {
      final assetPath = call.audioAssetPath.replaceFirst('assets/', '');
      try {
        await _audioPlayer.stop();
        await _audioPlayer.play(AssetSource(assetPath));
        setState(() => _currentlyPlayingId = call.id);
        
        _audioPlayer.onPlayerComplete.listen((_) {
          if (mounted) setState(() => _currentlyPlayingId = null);
        });
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Could not play audio: $e"), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  void _navigateToDetail(ReferenceCall call) {
    if (call.isLocked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Coming Soon! This call will be available in the next update.")),
      );
      return;
    }
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CallDetailScreen(
          call: call, 
          userId: widget.userId ?? 'anonymous'
        ),
      ),
    );
  }

  List<ReferenceCall> _getFilteredCalls(String category) {
    return ReferenceDatabase.calls.where((call) {
      final matchesSearch = call.animalName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          call.callType.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesCategory = category == "All" || call.category == category;
      return matchesSearch && matchesCategory;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: _categories.length,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          title: Text('CALL LIBRARY', style: GoogleFonts.oswald(fontWeight: FontWeight.bold, letterSpacing: 1.5)),
          backgroundColor: Colors.transparent,
          elevation: 0,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(100),
            child: Column(
              children: [
                // Search Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: TextField(
                    onChanged: (val) => setState(() => _searchQuery = val),
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "Search calls...",
                      hintStyle: const TextStyle(color: Colors.white54),
                      prefixIcon: const Icon(Icons.search, color: Colors.white54),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.1),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    ),
                  ),
                ),
                // Tabs
                TabBar(
                  isScrollable: true,
                  indicatorColor: const Color(0xFF81C784),
                  labelColor: const Color(0xFF81C784),
                  unselectedLabelColor: Colors.white54,
                  labelStyle: GoogleFonts.oswald(fontWeight: FontWeight.bold),
                  tabs: _categories.map((cat) => Tab(text: cat.toUpperCase())).toList(),
                ),
              ],
            ),
          ),
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
            top: false,
            child: TabBarView(
              children: _categories.map((category) {
                final filtered = _getFilteredCalls(category);
                if (filtered.isEmpty) {
                  return const Center(child: Text("No calls found", style: TextStyle(color: Colors.white54)));
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 220, 16, 16),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final call = filtered[index];
                    final isPlaying = _currentlyPlayingId == call.id;
                    return _buildCallCard(call, isPlaying);
                  },
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCallCard(ReferenceCall call, bool isPlaying) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _navigateToDetail(call),
        borderRadius: BorderRadius.circular(16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: call.isLocked
                      ? Colors.black.withValues(alpha: 0.3)
                      : isPlaying 
                          ? const Color(0xFF81C784).withValues(alpha: 0.2)
                          : Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: call.isLocked
                        ? Colors.white.withValues(alpha: 0.05)
                        : isPlaying 
                            ? const Color(0xFF81C784).withValues(alpha: 0.5)
                            : Colors.white.withValues(alpha: 0.1),
                  ),
                ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                        _buildPlayButton(call, isPlaying),
                      const SizedBox(width: 16),
                      // Names
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              call.callType,
                              style: GoogleFonts.oswald(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              call.animalName,
                              style: TextStyle(
                                color: call.isLocked ? Colors.white38 : Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Difficulty Badge
                      _buildDifficultyBadge(call.difficulty),
                    ],
                  ),
                  if (call.description.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      call.description,
                      style: const TextStyle(color: Colors.white54, fontSize: 13, fontStyle: FontStyle.italic),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildMetricChip(Icons.music_note, "${call.idealPitchHz.toInt()} Hz"),
                      const SizedBox(width: 8),
                      _buildMetricChip(Icons.timer_outlined, "${call.idealDurationSec}s"),
                      const SizedBox(width: 8),
                      const Spacer(),
                      // Learn More Indicator
                      if (call.proTips.isNotEmpty)
                        const Icon(Icons.info_outline, size: 16, color: Colors.white30),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        difficulty.toUpperCase(),
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildMetricChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white70),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
        ],
      ),
    );
  }
  Widget _buildPlayButton(ReferenceCall call, bool isPlaying) {
    return InkWell(
      onTap: () => _togglePlayback(call),
      child: Icon(
        call.isLocked 
            ? Icons.lock_outline 
            : isPlaying ? Icons.stop_circle_rounded : Icons.play_circle_filled_rounded,
        color: call.isLocked
            ? Colors.white24
            : isPlaying ? const Color(0xFF81C784) : Colors.white70,
        size: 40,
      ),
    );
  }
}
