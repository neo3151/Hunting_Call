import 'package:flutter/material.dart';
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
      appBar: AppBar(title: const Text('Analysis Result')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : result == null 
              ? const Center(child: Text("Analysis failed."))
              : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 150,
                          height: 150,
                          child: CircularProgressIndicator(
                            value: result!.score / 100,
                            strokeWidth: 12,
                            color: _getScoreColor(result!.score),
                            backgroundColor: Colors.grey.shade200,
                          ),
                        ),
                         Text(
                          "${result!.score.toStringAsFixed(0)}%",
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: _getScoreColor(result!.score),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Score Text Label
                     Text(
                      "Overall Score",
                       style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        "Detected Pitch: ${result!.pitchHz.toStringAsFixed(1)} Hz",
                        style: TextStyle(
                          fontFamily: 'monospace',
                          color: Colors.grey.shade800,
                          fontWeight: FontWeight.w600
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _getScoreColor(result!.score).withOpacity(0.5), width: 2),
                        boxShadow: [
                           BoxShadow(
                             color: Colors.black.withOpacity(0.05),
                             blurRadius: 10,
                             offset: const Offset(0, 4),
                           )
                        ]
                      ),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                               Icon(Icons.assistant, color: _getScoreColor(result!.score)),
                               const SizedBox(width: 8),
                               Text("AI Feedback", style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const Divider(height: 24),
                          Text(
                            result!.feedback,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.5),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 20),
                  ...result!.metrics.entries.map((e) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(e.key),
                            const SizedBox(width: 10),
                            Expanded(child: LinearProgressIndicator(value: e.value / 100)),
                            const SizedBox(width: 10),
                            Text(e.value.toStringAsFixed(0)),
                          ],
                        ),
                      )),
                  const SizedBox(height: 40),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                    child: const Text('Back to Dashboard'),
                  ),
                ],
              ),
            ),
    );
  }
  Color _getScoreColor(double score) {
    if (score >= 80) return Colors.green;
    if (score >= 50) return Colors.orange;
    return Colors.red;
  }
}
