import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../injection_container.dart';
import '../domain/rating_model.dart';
import '../domain/rating_service.dart';

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
                      
                      // Detailed Metrics
                      ...result!.metrics.entries.map((e) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(e.key.toUpperCase(), style: GoogleFonts.oswald(color: Colors.white70, fontSize: 12, letterSpacing: 1.0)),
                                    Text("${e.value.toStringAsFixed(0)}%", style: GoogleFonts.oswald(color: Colors.white, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: e.value / 100,
                                    minHeight: 8,
                                    backgroundColor: Colors.white.withValues(alpha: 0.05),
                                    color: _getScoreColor(e.value.toDouble()),
                                  ),
                                ),
                              ],
                            ),
                          )),
                          
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
}
