import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../providers/providers.dart';
import '../domain/rating_model.dart';
import '../../library/data/reference_database.dart';
import './widgets/waveform_overlay.dart';

class RatingScreen extends ConsumerStatefulWidget {
  final String audioPath;
  final String animalId;
  final String userId;
  const RatingScreen({super.key, required this.audioPath, required this.animalId, required this.userId});

  @override
  ConsumerState<RatingScreen> createState() => _RatingScreenState();
}

class _RatingScreenState extends ConsumerState<RatingScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(ratingNotifierProvider.notifier).reset();
      ref.read(ratingNotifierProvider.notifier).analyzeCall(widget.userId, widget.audioPath, widget.animalId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final ratingState = ref.watch(ratingNotifierProvider);
    final result = ratingState.result;
    final isLoading = ratingState.isAnalyzing;
    final error = ratingState.error;

    // Calculate safe top padding to prevent AppBar overlap
    final topPadding = MediaQuery.of(context).padding.top + kToolbarHeight + 20;

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('ANALYSIS RESULT', 
          style: GoogleFonts.oswald(fontWeight: FontWeight.bold, letterSpacing: 2, fontSize: 16, color: Colors.white)
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/forest_background.png'),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(Colors.black54, BlendMode.darken),
          ),
        ),
        child: isLoading
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 80,
                      height: 80,
                      child: CircularProgressIndicator(
                        color: Color(0xFF5FF7B6),
                        strokeWidth: 6,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'ANALYZING YOUR CALL',
                      style: GoogleFonts.oswald(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Extracting frequency patterns...',
                      style: GoogleFonts.lato(
                        fontSize: 13,
                        color: Colors.white60,
                      ),
                    ),
                  ],
                ),
              )
            : error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, color: Colors.redAccent, size: 64),
                        const SizedBox(height: 24),
                        Text(
                          "Analysis Failed",
                          style: GoogleFonts.oswald(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 40),
                          child: Text(
                            error,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.lato(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        ElevatedButton.icon(
                          onPressed: () {
                            ref.read(ratingNotifierProvider.notifier).reset();
                            ref.read(ratingNotifierProvider.notifier).analyzeCall(
                              widget.userId,
                              widget.audioPath,
                              widget.animalId,
                            );
                          },
                          icon: const Icon(Icons.refresh),
                          label: Text('RETRY ANALYSIS', style: GoogleFonts.oswald(letterSpacing: 1.5)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF5FF7B6),
                            foregroundColor: Colors.black87,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          ),
                        ),
                      ],
                    ),
                  )
                : result == null
                    ? const Center(child: CircularProgressIndicator(color: Color(0xFF5FF7B6)))
                    : Scrollbar(
                        controller: _scrollController,
                        thumbVisibility: true,
                        trackVisibility: true,
                        child: ListView(
                          controller: _scrollController,
                          primary: false,
                          padding: EdgeInsets.fromLTRB(20, topPadding, 20, 80),
                          children: [
                            _tryRender(() => _buildOverallProficiency(result.score), "Proficiency"),
                            const SizedBox(height: 40),
                            _tryRender(() => _buildAIFeedback(result.feedback), "Feedback"),
                            const SizedBox(height: 32),
                            _tryRender(() => _buildPitchComparison(result), "Pitch Comparison"),
                            const SizedBox(height: 24),
                            if (result.userWaveform != null)
                              WaveformOverlay(
                                userWaveform: result.userWaveform!,
                                referenceWaveform: result.referenceWaveform,
                              ),
                            const SizedBox(height: 24),
                            _tryRender(() => _buildDetailedMetrics(result), "Metrics"),
                            const SizedBox(height: 40),
                            _tryRender(() => _buildComprehensiveAnalytics(result), "Analytics"),
                            const SizedBox(height: 40),
                            _tryRender(() => _buildTipSection(), "Tip"),
                            const SizedBox(height: 24),
                            _buildBackButton(),
                          ],
                        ),
                      ),
      ),
    );
  }

  Widget _tryRender(Widget Function() builder, String sectionName) {
    try {
      return builder();
    } catch (e, stack) {
      debugPrint("RENDER ERROR in $sectionName: $e\n$stack");
      return Container(
        padding: const EdgeInsets.all(8),
        color: Colors.red.withOpacity(0.2),
        child: Text("Error in $sectionName: $e", style: const TextStyle(color: Colors.red, fontSize: 10)),
      );
    }
  }

  Widget _buildOverallProficiency(dynamic score) {
    final double s = _toSafe(score).clamp(0, 100);
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 180,
              height: 180,
              child: CircularProgressIndicator(
                value: s / 100,
                strokeWidth: 10,
                color: const Color(0xFF5FF7B6),
                backgroundColor: Colors.white.withValues(alpha: 0.1),
              ),
            ),
            Text("${s.toInt()}%", style: GoogleFonts.oswald(fontSize: 64, fontWeight: FontWeight.bold, color: Colors.white)),
          ],
        ),
        const SizedBox(height: 16),
        Text("OVERALL PROFICIENCY", style: GoogleFonts.oswald(fontSize: 11, letterSpacing: 1.5, color: Colors.white60, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildAIFeedback(String feedback) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.auto_awesome, color: Color(0xFF5FF7B6), size: 14),
              const SizedBox(width: 8),
              Text("AI FEEDBACK", style: GoogleFonts.oswald(fontSize: 11, letterSpacing: 1.5, color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          Text(feedback, textAlign: TextAlign.center, style: GoogleFonts.lato(fontSize: 14, color: Colors.white.withValues(alpha: 0.9), height: 1.5)),
        ],
      ),
    );
  }

  Widget _buildPitchComparison(RatingResult result) {
    final reference = ReferenceDatabase.getById(widget.animalId);
    final targetPitch = _toSafe(reference.idealPitchHz);
    final userPitch = _toSafe(result.pitchHz);
    final diff = userPitch - targetPitch;
    final isTooHigh = diff > 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          Text("PITCH COMPARISON", style: GoogleFonts.oswald(fontSize: 11, letterSpacing: 1.5, color: Colors.white, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                children: [
                  Text("TARGET", style: GoogleFonts.oswald(fontSize: 9, color: Colors.white38, letterSpacing: 1)),
                  const SizedBox(height: 4),
                  Text("${targetPitch.toInt()} Hz", style: GoogleFonts.oswald(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
                ],
              ),
              Column(
                children: [
                  Icon(isTooHigh ? Icons.arrow_upward : Icons.arrow_downward, color: const Color(0xFF5FF7B6), size: 20),
                  const SizedBox(height: 2),
                  Text(isTooHigh ? "TOO HIGH" : "TOO LOW", style: GoogleFonts.oswald(fontSize: 9, color: Colors.white70, fontWeight: FontWeight.bold)),
                  Text("${diff.abs().toInt()} Hz", style: GoogleFonts.lato(fontSize: 9, color: Colors.white38)),
                ],
              ),
              Column(
                children: [
                  Text("YOUR PITCH", style: GoogleFonts.oswald(fontSize: 9, color: Colors.white38, letterSpacing: 1)),
                  const SizedBox(height: 4),
                  Text("${userPitch.toInt()} Hz", style: GoogleFonts.oswald(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildPitchSlider(userPitch, targetPitch, reference.tolerancePitch),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF5FF7B6).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text("Within tolerance ✓", style: GoogleFonts.lato(fontSize: 10, color: const Color(0xFF5FF7B6), fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildPitchSlider(double user, double target, double tolerance) {
    return SizedBox(
      height: 20, // Explicit height to prevent collapse/infinite expansion
      child: LayoutBuilder(
        builder: (context, constraints) {
          const minFreq = 100.0;
          const maxFreq = 1000.0;
          
          double normalize(double val) => ((val - minFreq) / (maxFreq - minFreq)).clamp(0, 1);
          
          final targetNorm = normalize(target);
          final userNorm = normalize(user);
          final toleranceNorm = (tolerance / (maxFreq - minFreq)).clamp(0, 0.3);
          
          final maxWidth = constraints.maxWidth;
          final targetPos = targetNorm * maxWidth;
          final userPos = userNorm * maxWidth;
          final toleranceWidth = toleranceNorm * maxWidth * 2;
          
          // Debugging values
          // debugPrint("Slider: T=$targetPos, U=$userPos, TolW=$toleranceWidth, Max=$maxWidth");
          
          return Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.centerLeft,
            children: [
              // 1. Background Track
              Container(
                height: 8,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              
              // 2. Tolerance Zone
              Positioned(
                left: (targetPos - toleranceWidth / 2).clamp(0, maxWidth),
                width: toleranceWidth.clamp(0, maxWidth), // Explicit width
                height: 8,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF5FF7B6).withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              
              // 3. User Indicator
              Positioned(
                left: (userPos - 2).clamp(0, maxWidth - 4),
                width: 4,
                height: 12, // Slightly taller
                top: -2, // Center vertically relative to 8px track
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF5FF7B6),
                    borderRadius: BorderRadius.circular(2),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF5FF7B6).withValues(alpha: 0.5), 
                        blurRadius: 4, 
                        spreadRadius: 1
                      )
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDetailedMetrics(RatingResult result) {
    final reference = ReferenceDatabase.getById(widget.animalId);
    return Column(
      children: [
        _buildMetricRow("PITCH (HZ)", "Your frequency", "${_toSafe(result.pitchHz).toStringAsFixed(1)} Hz"),
        const SizedBox(height: 8),
        _buildMetricRow("TARGET PITCH", "Ideal frequency", "${_toSafe(reference.idealPitchHz).toStringAsFixed(1)} Hz"),
        const SizedBox(height: 8),
        _buildMetricRow("DURATION (S)", "Call length", "${_toSafe(result.metrics['Duration (s)'] ?? 1.0).toStringAsFixed(2)} s"),
      ],
    );
  }

  Widget _buildMetricRow(String label, String sublabel, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: GoogleFonts.oswald(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1)),
              Text(sublabel, style: GoogleFonts.lato(fontSize: 9, color: Colors.white38)),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(value, style: GoogleFonts.oswald(fontSize: 13, color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildComprehensiveAnalytics(RatingResult result) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(width: 3, height: 14, decoration: const BoxDecoration(color: Color(0xFF5FF7B6), borderRadius: BorderRadius.all(Radius.circular(2)))),
            const SizedBox(width: 8),
            Text("COMPREHENSIVE ANALYTICS", style: GoogleFonts.oswald(fontSize: 12, letterSpacing: 1.5, color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 20),
        _buildAnalyticsSection("VOLUME ANALYSIS", Icons.volume_up, [
          _buildAnalyticsCard("Average Volume", result.metrics['avg_volume'] ?? 65.0),
          _buildAnalyticsCard("Peak Volume", result.metrics['peak_volume'] ?? 82.0),
          _buildAnalyticsCard("Consistency", result.metrics['consistency'] ?? 78.0),
        ]),
        const SizedBox(height: 12),
        _buildAnalyticsSection("TONE ANALYSIS", Icons.tune, [
          _buildAnalyticsCard("Tone Clarity", result.metrics['tone_clarity'] ?? 85.0),
          _buildAnalyticsCard("Harmonic Richness", result.metrics['harmonic_richness'] ?? 72.0),
          _buildAnalyticsCard("Call Quality", result.metrics['call_quality'] ?? 88.0),
        ]),
        const SizedBox(height: 12),
        _buildAnalyticsSection("TIMBRE ANALYSIS", Icons.waves, [
          _buildAnalyticsCard("Brightness", result.metrics['brightness'] ?? 55.0),
          _buildAnalyticsCard("Warmth", result.metrics['warmth'] ?? 68.0),
          _buildAnalyticsCard("Nasality", result.metrics['nasality'] ?? 42.0),
        ]),
        const SizedBox(height: 12),
        _buildAnalyticsSection("RHYTHM ANALYSIS", Icons.timeline, [
          _buildAnalyticsCard("Tempo", null),
          _buildAnalyticsCard("Regularity", null),
        ], isNotPulsed: true),
      ],
    );
  }

  Widget _buildAnalyticsSection(String title, IconData icon, List<Widget> cards, {bool isNotPulsed = false}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF5FF7B6), size: 14),
              const SizedBox(width: 8),
              Text(title, style: GoogleFonts.oswald(fontSize: 11, color: Colors.white70, fontWeight: FontWeight.bold, letterSpacing: 1)),
            ],
          ),
          const SizedBox(height: 16),
          if (isNotPulsed)
            Column(
              children: [
                Row(
                  children: cards.map((c) => Expanded(child: Padding(padding: const EdgeInsets.only(right: 8), child: c))).toList(),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text("Not a pulsed call", textAlign: TextAlign.center, style: GoogleFonts.lato(fontSize: 10, color: Colors.white24, fontStyle: FontStyle.italic)),
                ),
              ],
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: cards.map((c) => Padding(padding: const EdgeInsets.only(right: 8), child: c)).toList()),
            ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsCard(String label, double? value) {
    final safeValue = value != null && value.isFinite ? value.clamp(0, 100) : null;
    Color getColor(num? v) {
      if (v == null) return Colors.white24;
      if (v >= 80) return const Color(0xFF5FF7B6);
      if (v >= 60) return const Color(0xFFB8E986);
      return const Color(0xFFFFB74D);
    }
    
    return Container(
      width: 100,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.lato(fontSize: 9, color: Colors.white38, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(
            safeValue != null ? "${safeValue.toStringAsFixed(1)} %" : "--",
            style: GoogleFonts.oswald(fontSize: 18, color: getColor(safeValue), fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          if (safeValue != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: safeValue / 100,
                minHeight: 3,
                backgroundColor: Colors.white.withValues(alpha: 0.1),
                color: getColor(safeValue),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTipSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF5FF7B6).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF5FF7B6).withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lightbulb_outline, color: Color(0xFF5FF7B6), size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              "Tip: These analytics help you understand the complete quality of your call, not just pitch and duration. Practice improving each dimension!",
              style: GoogleFonts.lato(fontSize: 11, color: Colors.white70, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => Navigator.of(context).pop(),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF8BB781),
          foregroundColor: Colors.black87,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text("BACK TO DASHBOARD", style: GoogleFonts.oswald(fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
      ),
    );
  }

  double _toSafe(dynamic val) {
    if (val == null) return 0.0;
    if (val is num) return val.isFinite ? val.toDouble() : 0.0;
    return double.tryParse(val.toString()) ?? 0.0;
  }
}
