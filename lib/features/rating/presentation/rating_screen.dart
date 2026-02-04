import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../providers/providers.dart';
import '../domain/rating_model.dart';
import '../../library/data/mock_reference_database.dart';

class RatingScreen extends ConsumerStatefulWidget {
  final String audioPath;
  final String animalId;
  final String userId;
  const RatingScreen({super.key, required this.audioPath, required this.animalId, required this.userId});

  @override
  ConsumerState<RatingScreen> createState() => _RatingScreenState();
}

class _RatingScreenState extends ConsumerState<RatingScreen> {
  @override
  void initState() {
    super.initState();
    // Start analysis on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(ratingNotifierProvider.notifier).analyzeCall(widget.userId, widget.audioPath, widget.animalId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final ratingState = ref.watch(ratingNotifierProvider);
    final result = ratingState.result;
    final isLoading = ratingState.isAnalyzing;
    final error = ratingState.error;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('ANALYSIS RESULT', style: GoogleFonts.oswald(fontWeight: FontWeight.bold, letterSpacing: 1.5)),
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
          child: isLoading
              ? const Center(child: CircularProgressIndicator(color: Colors.greenAccent))
              : error != null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red, size: 64),
                          const SizedBox(height: 16),
                          Text("Analysis failed: $error", style: GoogleFonts.lato(color: Colors.white)),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: () => ref.read(ratingNotifierProvider.notifier).analyzeCall(widget.userId, widget.audioPath, widget.animalId),
                            child: const Text("Retry"),
                          ),
                        ],
                      ),
                    )
                  : result == null 
                      ? Center(child: Text("Analysis failed.", style: GoogleFonts.lato(color: Colors.white)))
                      : SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                            const SizedBox(height: 20),
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                SizedBox(
                                  width: 180,
                                  height: 180,
                                  child: CircularProgressIndicator(
                                    value: result.score / 100,
                                    strokeWidth: 12,
                                    color: _getScoreColor(result.score),
                                    backgroundColor: Colors.white.withValues(alpha: 0.1),
                                  ),
                                ),
                                 Text(
                                   "${result.score.toStringAsFixed(0)}%",
                                   style: GoogleFonts.oswald(
                                     fontSize: 48,
                                     fontWeight: FontWeight.bold,
                                     color: Colors.white,
                                   ),
                                 ),
                              ],
                            ),
                            const SizedBox(height: 32),
                            Text(
                              result.feedback,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.lato(
                                fontSize: 20,
                                color: Colors.white,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                            const SizedBox(height: 48),

                            // Pitch Analysis Visualization (from remote)
                            _buildPitchComparisonCard(result),
                            
                            const SizedBox(height: 24),
                            
                            // Metrics Grid
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                                childAspectRatio: 1.5,
                              ),
                              itemCount: result.metrics.length,
                              itemBuilder: (context, index) {
                                final key = result.metrics.keys.elementAt(index);
                                final value = result.metrics[key]!;
                                return _buildMetricCard(key, value);
                              },
                            ),

                            const SizedBox(height: 32),
                            
                            // Comprehensive Analytics Section (from remote)
                            _buildComprehensiveAnalytics(result),

                            const SizedBox(height: 48),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () => Navigator.of(context).pop(),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white.withValues(alpha: 0.1),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 20),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                                  ),
                                ),
                                child: Text('DISMISS', style: GoogleFonts.oswald(fontWeight: FontWeight.bold, letterSpacing: 2)),
                              ),
                            ),
                            const SizedBox(height: 24),
                        ],
                      ),
                    ),
        ),
      ),
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 80) return Colors.greenAccent;
    if (score >= 50) return Colors.orangeAccent;
    return Colors.redAccent;
  }

  Widget _buildPitchComparisonCard(RatingResult result) {
    // New visualization component from remote
    final reference = MockReferenceDatabase.getById(widget.animalId);
    final userPitch = result.pitchHz;
    final targetPitch = reference.idealPitchHz;
    
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("PITCH FREQUENCY", style: GoogleFonts.oswald(color: Colors.white70, fontSize: 14, letterSpacing: 1.5)),
              const SizedBox(height: 24),
              LayoutBuilder(
                builder: (context, constraints) {
                  return Stack(
                    children: [
                      // Frequency Line
                      Container(
                        height: 4,
                        margin: const EdgeInsets.symmetric(vertical: 20),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      // Target Range (Shaded area)
                      Positioned(
                        left: _calculatePitchPosition(targetPitch - reference.tolerancePitch, targetPitch, context) * constraints.maxWidth,
                        width: (_calculatePitchPosition(targetPitch + reference.tolerancePitch, targetPitch, context) - 
                                _calculatePitchPosition(targetPitch - reference.tolerancePitch, targetPitch, context)) * constraints.maxWidth,
                        child: Container(
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.greenAccent.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      // Target Pointer
                      Positioned(
                        left: _calculatePitchPosition(targetPitch, targetPitch, context) * constraints.maxWidth - 1,
                        child: Column(
                          children: [
                            Container(width: 2, height: 44, color: Colors.greenAccent),
                            const SizedBox(height: 4),
                            Text("${targetPitch.toInt()}Hz", style: GoogleFonts.lato(color: Colors.greenAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      // User Pointer
                      Positioned(
                        left: _calculatePitchPosition(userPitch, targetPitch, context) * constraints.maxWidth - 20,
                        child: Column(
                          children: [
                            const Icon(Icons.location_on, color: Colors.blueAccent, size: 24),
                            const SizedBox(height: 20),
                            Text("${userPitch.toInt()}Hz", style: GoogleFonts.lato(color: Colors.blueAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 50),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                   _buildSmallLegend("TARGET", Colors.greenAccent),
                   _buildSmallLegend("YOU", Colors.blueAccent),
                   _buildSmallLegend("TOLERANCE", Colors.greenAccent.withValues(alpha: 0.3)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  double _calculatePitchPosition(double current, double target, BuildContext context) {
    // Relative position on a logarithmic or linear scale for visualization
    const minFreq = 50.0;
    final maxFreq = (target * 2).clamp(1000.0, 5000.0);
    
    final normalized = (current - minFreq) / (maxFreq - minFreq);
    return normalized.clamp(0.0, 1.0);
  }

  Widget _buildSmallLegend(String label, Color color) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 8),
        Text(label, style: GoogleFonts.lato(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildMetricCard(String key, double value) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(key.toUpperCase(), style: GoogleFonts.oswald(color: Colors.white54, fontSize: 10, letterSpacing: 1)),
              const SizedBox(height: 4),
              FittedBox(
                child: Text(
                  value % 1 == 0 ? value.toInt().toString() : value.toStringAsFixed(2),
                  style: GoogleFonts.oswald(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 4),
              Text(_getMetricDescription(key), style: GoogleFonts.lato(color: Colors.white38, fontSize: 9)),
            ],
          ),
        ),
      ),
    );
  }

  String _getMetricDescription(String key) {
    switch (key.toLowerCase()) {
      case 'pitch (hz)': return 'Dominant frequency detected';
      case 'target pitch': return 'Ideal frequency for this call';
      case 'duration (s)': return 'Total length of your call';
      default: return 'Call characteristic';
    }
  }

  Widget _buildComprehensiveAnalytics(RatingResult result) {
    // This is from the remote pull - adding high-fidelity mock analytics
    return Column(
      children: [
        _buildAnalyticsSectionHeader("ADVANCED SPECTRUM ANALYSIS"),
        const SizedBox(height: 16),
        _buildAnalyticsCategory(
          "HARMONIC FIDELITY", 
          Icons.auto_graph_rounded,
          [
            _buildAnalyticsMetric("Fundamental Sync", 94.2, "%", Colors.greenAccent),
            _buildAnalyticsMetric("Overtone Stability", 82.5, "%", Colors.orangeAccent),
          ]
        ),
        const SizedBox(height: 16),
        _buildAnalyticsCategory(
          "TIMBRAL TEXTURE", 
          Icons.waves_rounded,
          [
            _buildAnalyticsMetric("Spectral Flux", 12.4, "dB", Colors.blueAccent),
            _buildAnalyticsMetric("Zero Crossing Rate", 458, "Hz", Colors.purpleAccent),
          ]
        ),
        const SizedBox(height: 16),
        _buildAnalyticsInfo("Your call exhibits strong fundamental stability but could benefit from more controlled breath support in the final 20% of the duration."),
      ],
    );
  }

  Widget _buildAnalyticsSectionHeader(String title) {
    return Row(
      children: [
        Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.1))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(title, style: GoogleFonts.oswald(color: Colors.white38, fontSize: 12, letterSpacing: 2)),
        ),
        Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.1))),
      ],
    );
  }

  Widget _buildAnalyticsCategory(String title, IconData icon, List<Widget> metrics) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.white38, size: 16),
              const SizedBox(width: 8),
              Text(title, style: GoogleFonts.oswald(color: Colors.white70, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: metrics,
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsMetric(String label, double value, String unit, Color color) {
    return Column(
      children: [
        Text(label, style: GoogleFonts.lato(color: Colors.white38, fontSize: 11)),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(_formatAnalyticsValue(value), style: GoogleFonts.oswald(color: color, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(width: 2),
            Text(unit, style: GoogleFonts.lato(color: Colors.white24, fontSize: 10)),
          ],
        ),
      ],
    );
  }

  Widget _buildAnalyticsInfo(String text) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blueAccent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: Colors.blueAccent, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: GoogleFonts.lato(color: Colors.white70, fontSize: 12, height: 1.5))),
        ],
      ),
    );
  }

  String _formatAnalyticsValue(double value) {
    if (value % 1 == 0) return value.toInt().toString();
    return value.toStringAsFixed(1);
  }
}
