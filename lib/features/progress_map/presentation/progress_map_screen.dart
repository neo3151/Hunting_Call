import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get_it/get_it.dart';
import '../../profile/data/profile_repository.dart';
import '../../profile/domain/profile_model.dart';
import '../../rating/domain/rating_model.dart';
import 'package:geolocator/geolocator.dart';

class ProgressMapScreen extends StatefulWidget {
  final String userId;
  
  const ProgressMapScreen({super.key, required this.userId});

  @override
  State<ProgressMapScreen> createState() => _ProgressMapScreenState();
}

class _ProgressMapScreenState extends State<ProgressMapScreen> {
  List<HistoryItem> _mappedResults = [];
  bool _isLoading = true;
  LatLng _initialCenter = const LatLng(37.0902, -95.7129); // Default US center

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final profile = await GetIt.I<ProfileRepository>().getProfile(widget.userId);
      
      // Get current location for map center
      try {
        final pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(timeLimit: Duration(seconds: 2)),
        );
        _initialCenter = LatLng(pos.latitude, pos.longitude);
      } catch (_) {}

      // Filter history for results with location and score > 70 (Successes)
      final mapped = profile.history.where((h) {
        final r = h.result;
        return r.latitude != null && r.longitude != null && r.score >= 70;
      }).toList();

      if (mounted) {
        setState(() {
          _mappedResults = mapped;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  HistoryItem? _selectedResult;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: Text("MY FIELD MAP", style: GoogleFonts.oswald(letterSpacing: 1.5, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1B5E20),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: Color(0xFF81C784)))
        : Stack(
            children: [
              FlutterMap(
                options: MapOptions(
                  initialCenter: _initialCenter,
                  initialZoom: 4,
                  onTap: (_, __) => setState(() => _selectedResult = null), // Deselect on map tap
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.hunting.calls.perfection',
                    tileBuilder: (context, widget, tile) {
                      return ColorFiltered(
                        colorFilter: const ColorFilter.mode(
                          Colors.grey, 
                          BlendMode.saturation,
                        ), 
                        child: ColorFiltered(
                          colorFilter: const ColorFilter.mode(
                            Colors.black54, 
                            BlendMode.darken,
                          ),
                          child: widget,
                        ),
                      );
                    },
                  ),
                  MarkerLayer(
                    markers: _mappedResults.map((item) {
                      final result = item.result;
                      final isSelected = _selectedResult == item;
                      return Marker(
                        point: LatLng(result.latitude!, result.longitude!),
                        width: isSelected ? 60 : 40,
                        height: isSelected ? 60 : 40,
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedResult = item),
                          child: Container(
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.greenAccent.withValues(alpha: 0.9) : Colors.white.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 4)],
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              _getAnimalEmoji(item.animalId), 
                              style: TextStyle(fontSize: isSelected ? 30 : 20),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
              
              // Stats Overlay
              Positioned(
                top: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Column(
                    children: [
                      Text("${_mappedResults.length}", style: GoogleFonts.oswald(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.greenAccent)),
                      Text("SUCCESSFUL HUNTS", style: GoogleFonts.lato(fontSize: 10, color: Colors.white70)),
                    ],
                  ),
                ),
              ),

              // Detail Card (Bottom Sheet style)
              if (_selectedResult != null)
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 32,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.5)),
                      boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 10, offset: Offset(0, 4))],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.greenAccent.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                             "${_selectedResult!.result.score.toInt()}",
                             style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: Colors.greenAccent),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_selectedResult!.animalId.toUpperCase().replaceAll('_', ' '), style: GoogleFonts.oswald(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 12)),
                              Text(
                                "Excellent Performance", 
                                style: GoogleFonts.lato(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              if (_selectedResult!.result.metrics['Duration (s)'] != null)
                                Text(
                                  "Duration: ${_selectedResult!.result.metrics['Duration (s)']!.toStringAsFixed(1)}s",
                                  style: const TextStyle(color: Colors.white38, fontSize: 12),
                                ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white54),
                          onPressed: () => setState(() => _selectedResult = null),
                        )
                      ],
                    ),
                  ),
                ),
            ],
          ),
    );
  }

  String _getAnimalEmoji(String animalId) {
    if (animalId.contains('duck') || animalId.contains('mallard')) return '🦆';
    if (animalId.contains('elk') || animalId.contains('deer') || animalId.contains('buck')) return '🦌';
    if (animalId.contains('coyote') || animalId.contains('wolf')) return '🐺';
    if (animalId.contains('turkey')) return '🦃';
    if (animalId.contains('goose')) return '🪿';
    if (animalId.contains('crow')) return '🐦‍⬛';
    return '🎯';
  }
}
