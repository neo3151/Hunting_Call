import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../injection_container.dart';
import '../domain/rating_model.dart';
import '../domain/rating_service.dart';
import '../../library/data/mock_reference_database.dart';

class RatingScreen extends StatefulWidget {
  final String audioPath;
  final String animalId;
  final String userId;
  const RatingScreen({super.key, required this.audioPath, required this.animalId, required this.userId});

  @override
  State<RatingScreen> createState() => _RatingScreenState();
}

class _RatingScreenState extends State<RatingScreen> {
  RatingResult? result;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _analyzeCall();
  }

  void _analyzeCall() async {
    try {
      final service = sl<RatingService>();
      final res = await service.rateCall(widget.userId, widget.audioPath, widget.animalId);
      if (mounted) {
        setState(() {
          result = res;
          isLoading = false;
        });
      }
    } catch (e, stack) {
      debugPrint("Error analyzing call: $e\n$stack");
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error analyzing call: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
                                value: result!.score / 100,
                                strokeWidth: 12,
                                color: _getScoreColor(result!.score),
                                backgroundColor: Colors.white.withValues(alpha: 0.1),
                              ),
                            ),
                             Text(
                               "${result!.score.toStringAsFixed(0)}%",
                               style: GoogleFonts.oswald(
                                 fontSize: 48,
                                 fontWeight: FontWeight.bold,
                                 color: Colors.white,
                               ),
                             ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "OVERALL PROFICIENCY",
                           style: GoogleFonts.oswald(color: Colors.white70, fontSize: 16, letterSpacing: 2.0),
                        ),
                        const SizedBox(height: 32),
                        
                        // AI Feedback Card
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                              ),
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                       Icon(Icons.auto_awesome, color: _getScoreColor(result!.score), size: 20),
                                       const SizedBox(width: 8),
                                       Text("AI FEEDBACK", style: GoogleFonts.oswald(fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.0)),
                                    ],
                                  ),
                                  const Divider(height: 32, color: Colors.white24),
                                  Text(
                                    result!.feedback,
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.lato(color: Colors.white, fontSize: 16, height: 1.6),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        
                      const SizedBox(height: 32),
                      
                      // Pitch Comparison Visual
                      _buildPitchComparisonCard(),
                      
                      const SizedBox(height: 32),
                      
                      // Detailed Metrics
                      ...result!.metrics.entries.map((e) => _buildMetricCard(e.key, e.value)),
                      
                      // COMPREHENSIVE ANALYTICS SECTION
                      const SizedBox(height: 32),
                      _buildComprehensiveAnalytics(),
                          
                      const SizedBox(height: 48),
                      
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF81C784),
                            foregroundColor: const Color(0xFF0F1E12),
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text('BACK TO DASHBOARD', style: GoogleFonts.oswald(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
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

  Widget _buildPitchComparisonCard() {
    if (result == null) return const SizedBox.shrink();
    
    final referenceCall = MockReferenceDatabase.getById(widget.animalId);
    final userPitch = result!.pitchHz;
    final targetPitch = referenceCall.idealPitchHz;
    final difference = userPitch - targetPitch;
    final percentDiff = (difference / targetPitch * 100).abs();
    
    final isHigher = difference > 0;
    final isTooFarOff = difference.abs() > referenceCall.tolerancePitch;
    
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Text(
                "PITCH COMPARISON",
                style: GoogleFonts.oswald(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 20),
              
              // Visual comparison bar
              Row(
                children: [
                  // Target pitch marker (left side)
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          "TARGET",
                          style: GoogleFonts.oswald(
                            color: Colors.greenAccent,
                            fontSize: 10,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "${targetPitch.toStringAsFixed(0)} Hz",
                          style: GoogleFonts.oswald(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Center indicator
                  Expanded(
                    flex: 2,
                    child: Column(
                      children: [
                        // Arrow indicator
                        Icon(
                          isHigher ? Icons.arrow_upward : Icons.arrow_downward,
                          color: isTooFarOff ? Colors.orangeAccent : Colors.greenAccent,
                          size: 32,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isHigher ? "TOO HIGH" : "TOO LOW",
                          style: GoogleFonts.oswald(
                            color: isTooFarOff ? Colors.orangeAccent : Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "${difference.abs().toStringAsFixed(0)} Hz ${isHigher ? 'higher' : 'lower'}",
                          style: GoogleFonts.lato(
                            color: Colors.white70,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Your pitch marker (right side)
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          "YOUR PITCH",
                          style: GoogleFonts.oswald(
                            color: isTooFarOff ? Colors.orangeAccent : Colors.greenAccent,
                            fontSize: 10,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "${userPitch.toStringAsFixed(0)} Hz",
                          style: GoogleFonts.oswald(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
              
              // Visual bar
              SizedBox(
                height: 28, // Increased height to accommodate taller indicator
                child: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    // Background bar
                    Positioned(
                      top: 8,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                    // Target zone (green in center)
                    Positioned(
                      top: 8,
                      left: MediaQuery.of(context).size.width * 0.35,
                      right: MediaQuery.of(context).size.width * 0.35,
                      child: Container(
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.greenAccent.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                    // User position indicator
                    Positioned(
                      top: 4,
                      left: _calculatePitchPosition(userPitch, targetPitch, context),
                      child: Container(
                        width: 4,
                        height: 20,
                        decoration: BoxDecoration(
                          color: isTooFarOff ? Colors.orangeAccent : Colors.greenAccent,
                          borderRadius: BorderRadius.circular(2),
                          boxShadow: [
                            BoxShadow(
                              color: (isTooFarOff ? Colors.orangeAccent : Colors.greenAccent)
                                  .withValues(alpha: 0.5),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Percentage difference
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isTooFarOff
                      ? Colors.orangeAccent.withValues(alpha: 0.2)
                      : Colors.greenAccent.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isTooFarOff
                      ? "${percentDiff.toStringAsFixed(1)}% off target"
                      : "Within tolerance ✓",
                  style: GoogleFonts.lato(
                    color: isTooFarOff ? Colors.orangeAccent : Colors.greenAccent,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  double _calculatePitchPosition(double userPitch, double targetPitch, BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width - 96; // Accounting for padding
    final difference = userPitch - targetPitch;
    final maxDifference = targetPitch * 0.5; // Show range of +/- 50% of target
    
    // Clamp the difference to prevent going off screen
    final clampedDiff = difference.clamp(-maxDifference, maxDifference);
    
    // Map to screen position (center is target)
    final normalizedPosition = (clampedDiff / maxDifference) * 0.5 + 0.5;
    return screenWidth * normalizedPosition;
  }

  Widget _buildMetricCard(String key, double value) {
    // Determine the unit and formatting based on the metric key
    String displayValue;
    String unit;
    
    if (key.toLowerCase().contains('pitch') || key.toLowerCase().contains('hz')) {
      displayValue = value.toStringAsFixed(1);
      unit = 'Hz';
    } else if (key.toLowerCase().contains('duration') || key.toLowerCase().contains('sec')) {
      displayValue = value.toStringAsFixed(2);
      unit = 's';
    } else {
      // For any other metrics, just show the number
      displayValue = value.toStringAsFixed(1);
      unit = '';
    }
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        key.toUpperCase(),
                        style: GoogleFonts.oswald(
                          color: Colors.white70,
                          fontSize: 12,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getMetricDescription(key),
                        style: GoogleFonts.lato(
                          color: Colors.white54,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Text(
                        displayValue,
                        style: GoogleFonts.oswald(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        unit,
                        style: GoogleFonts.lato(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getMetricDescription(String key) {
    if (key.toLowerCase().contains('pitch') && key.toLowerCase().contains('target')) {
      return 'Ideal frequency';
    } else if (key.toLowerCase().contains('pitch')) {
      return 'Your frequency';
    } else if (key.toLowerCase().contains('duration')) {
      return 'Call length';
    }
    return '';
  }

  /// Build comprehensive analytics section with mock data for now
  Widget _buildComprehensiveAnalytics() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        _buildAnalyticsSectionHeader("COMPREHENSIVE ANALYTICS"),
        const SizedBox(height: 16),
        
        // Volume Analysis
        _buildAnalyticsCategory(
          "VOLUME ANALYSIS",
          Icons.volume_up,
          [
            _buildAnalyticsMetric("Average Volume", 65.0, "%", Colors.greenAccent),
            _buildAnalyticsMetric("Peak Volume", 82.0, "%", Colors.lightGreenAccent),
            _buildAnalyticsMetric("Consistency", 78.0, "%", Colors.greenAccent),
          ],
        ),
        
        const SizedBox(height: 20),
        
        // Tone Analysis
        _buildAnalyticsCategory(
          "TONE ANALYSIS",
          Icons.tune,
          [
            _buildAnalyticsMetric("Tone Clarity", 85.0, "%", Colors.greenAccent),
            _buildAnalyticsMetric("Harmonic Richness", 72.0, "%", Colors.lightGreenAccent),
            _buildAnalyticsMetric("Call Quality", 88.0, "%", Colors.greenAccent),
          ],
        ),
        
        const SizedBox(height: 20),
        
        // Timbre Analysis
        _buildAnalyticsCategory(
          "TIMBRE ANALYSIS",
          Icons.graphic_eq,
          [
            _buildAnalyticsMetric("Brightness", 55.0, "%", Colors.orangeAccent),
            _buildAnalyticsMetric("Warmth", 68.0, "%", Colors.lightGreenAccent),
            _buildAnalyticsMetric("Nasality", 42.0, "%", Colors.orangeAccent),
          ],
        ),
        
        const SizedBox(height: 20),
        
        // Rhythm Analysis (if applicable)
        _buildAnalyticsCategory(
          "RHYTHM ANALYSIS",
          Icons.insights,
          [
            _buildAnalyticsMetric("Tempo", 0.0, "BPM", Colors.white54),
            _buildAnalyticsMetric("Regularity", 0.0, "%", Colors.white54),
            _buildAnalyticsInfo("Not a pulsed call"),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Info note
        _buildAnalyticsNote(
          "💡 Tip: These analytics help you understand the complete quality of your call, "
          "not just pitch and duration. Practice improving each dimension!"
        ),
      ],
    );
  }

  Widget _buildAnalyticsSectionHeader(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 24,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.greenAccent, Colors.lightGreenAccent],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: GoogleFonts.oswald(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 2.0,
          ),
        ),
      ],
    );
  }

  Widget _buildAnalyticsCategory(String title, IconData icon, List<Widget> metrics) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: Colors.greenAccent, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: GoogleFonts.oswald(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white70,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: metrics,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnalyticsMetric(String label, double value, String unit, Color color) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.lato(
              color: Colors.white60,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value == 0.0 ? "—" : _formatAnalyticsValue(value),
                style: GoogleFonts.oswald(
                  color: value == 0.0 ? Colors.white30 : color,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (value > 0.0 && unit.isNotEmpty) ...[
                const SizedBox(width: 4),
                Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Text(
                    unit,
                    style: GoogleFonts.lato(
                      color: Colors.white.withValues(alpha: 0.4),
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (value > 0.0) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: _normalizeAnalyticsValue(value, unit),
                minHeight: 4,
                backgroundColor: Colors.white.withValues(alpha: 0.1),
                color: color,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAnalyticsInfo(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Text(
        text,
        style: GoogleFonts.lato(
          color: Colors.white54,
          fontSize: 12,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }

  Widget _buildAnalyticsNote(String text) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.greenAccent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.lightbulb_outline, color: Colors.greenAccent, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.lato(
                color: Colors.white70,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatAnalyticsValue(double value) {
    if (value >= 100) return value.toStringAsFixed(0);
    if (value >= 10) return value.toStringAsFixed(1);
    return value.toStringAsFixed(1);
  }

  double _normalizeAnalyticsValue(double value, String unit) {
    if (unit == "%") return value / 100;
    if (unit == "Hz") return (value / 2000).clamp(0.0, 1.0);
    if (unit == "s") return (value / 5).clamp(0.0, 1.0);
    if (unit == "BPM") return (value / 120).clamp(0.0, 1.0);
    return 0.5;
  }
}
