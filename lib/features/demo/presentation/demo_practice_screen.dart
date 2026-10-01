import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:outcall/core/theme/app_colors.dart';
import 'package:outcall/core/widgets/background_wrapper.dart';
import 'package:outcall/features/demo/demo_mode_controller.dart';
import 'package:outcall/features/profile/presentation/controllers/profile_controller.dart';
import 'package:outcall/features/rating/domain/rating_model.dart';

import 'package:outcall/core/widgets/main_shell.dart';
import 'package:outcall/features/demo/presentation/executive_pitch_dialog.dart';

class DemoPracticeScreen extends ConsumerStatefulWidget {
  final String userId;

  const DemoPracticeScreen({super.key, required this.userId});

  @override
  ConsumerState<DemoPracticeScreen> createState() => _DemoPracticeScreenState();
}

class _DemoPracticeScreenState extends ConsumerState<DemoPracticeScreen> {
  final _species = const ['Duck', 'Turkey', 'Elk', 'Coyote'];
  final _scenarios = const ['Solid attempt', 'Expert attempt', 'Pitch trouble', 'Wind interference'];

  String _selectedSpecies = 'Duck';
  String _selectedScenario = 'Solid attempt';
  bool _isAnalyzing = false;
  int _analysisStep = 0;
  RatingResult? _result;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _runSampleCall() async {
    if (_isAnalyzing) return;

    setState(() {
      _isAnalyzing = true;
      _analysisStep = 0;
      _result = null;
    });

    _timer = Timer.periodic(const Duration(milliseconds: 700), (timer) {
      if (!mounted) return;
      setState(() => _analysisStep = (_analysisStep + 1).clamp(0, 3));
    });

    await Future<void>.delayed(const Duration(milliseconds: 2800));
    _timer?.cancel();

    final result = _buildResult();
    await ref.read(profileNotifierProvider.notifier).saveResult(
          widget.userId,
          result,
          _selectedSpecies.toLowerCase(),
        );
    ref.read(demoModeProvider.notifier).addXp(50);

    if (mounted) {
      setState(() {
        _isAnalyzing = false;
        _result = result;
        _analysisStep = 3;
      });
    }
  }

  RatingResult _buildResult() {
    final score = switch (_selectedScenario) {
      'Expert attempt' => 94.0,
      'Pitch trouble' => 58.0,
      'Wind interference' => 42.0,
      _ => 82.0,
    };
    final pitch = switch (_selectedSpecies) {
      'Turkey' => 748.0,
      'Elk' => 892.0,
      'Coyote' => 1390.0,
      _ => 334.0,
    };
    final feedback = switch (_selectedScenario) {
      'Expert attempt' => 'Excellent control. That call is ready for the field.',
      'Pitch trouble' => 'Your rhythm is promising. Focus on keeping the pitch centered.',
      'Wind interference' => 'The call is getting buried in noise. Move behind cover and try again.',
      _ => 'Solid cadence and tone. Tighten the final note for a cleaner finish.',
    };

    return RatingResult(
      score: score,
      feedback: feedback,
      pitchHz: pitch,
      metrics: {
        'score_pitch': _selectedScenario == 'Pitch trouble' ? 54.0 : score + 2,
        'score_duration': score - 3,
        'score_timbre': _selectedScenario == 'Wind interference' ? 38.0 : score + 4,
        'score_rhythm': score - 1,
      },
      archetypeLabel: _selectedScenario == 'Expert attempt' ? 'Field Ready' : 'Building Momentum',
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final demo = ref.watch(demoModeProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('SAMPLE CALL LAB', style: GoogleFonts.oswald(letterSpacing: 1.1)),
        centerTitle: false,
        backgroundColor: Colors.transparent,
        actions: [
          if (demo.isPresenterMode)
            IconButton(
              icon: const Icon(Icons.qr_code_2_rounded, color: Colors.tealAccent),
              tooltip: 'Executive Pitch Hub',
              onPressed: () => ExecutivePitchDialog.show(context),
            ),
          const SizedBox(width: 8),
        ],
      ),

      body: BackgroundWrapper(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                children: [
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                    decoration: BoxDecoration(
                      color: colors.surface.withOpacity(0.85),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.accentGold.withOpacity(0.35)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.info_outline_rounded, color: AppColors.accentGold, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Acoustic Telemetry Preview: Full hardware microphone DSP & real-time spectrogram analysis run natively on iOS & Android. Web demo simulates audio capture to bypass browser permission hurdles.',
                            style: TextStyle(color: colors.textSecondary, fontSize: 11.5, height: 1.35),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    'See how OUTCALL coaches a call',
                    style: GoogleFonts.oswald(fontSize: 28, color: colors.textPrimary),
                  ),
              const SizedBox(height: 8),
              Text(
                'Choose a species and scenario. No microphone or account connection is needed in demo mode.',
                style: TextStyle(color: colors.textSecondary, height: 1.4),
              ),
              const SizedBox(height: 24),
              _buildSelector('Species', _selectedSpecies, _species, (value) {
                setState(() => _selectedSpecies = value!);
              }),
              const SizedBox(height: 14),
              _buildSelector('Scenario', _selectedScenario, _scenarios, (value) {
                setState(() => _selectedScenario = value!);
              }),
              const SizedBox(height: 24),
              if (_isAnalyzing) _buildAnalysisState(colors) else _buildAction(colors),
              if (_result != null) ...[
                const SizedBox(height: 24),
                _buildResultCard(colors),
              ],
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (_) => const MainShell(userId: 'prospect_guest'),
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: BorderSide(color: AppColors.accentGold.withOpacity(0.8), width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  backgroundColor: AppColors.accentGold.withOpacity(0.08),
                ),
                icon: const Icon(Icons.explore_rounded, color: AppColors.accentGold),
                label: Text(
                  'EXPLORE FULL APP DEMO (5 TABS)',
                  style: GoogleFonts.oswald(
                    color: AppColors.accentGold,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                '${demo.xp} XP  •  Demo Mode',
                textAlign: TextAlign.center,
                style: TextStyle(color: colors.textTertiary, fontSize: 12),
              ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSelector(
    String label,
    String value,
    List<String> values,
    ValueChanged<String?> onChanged,
  ) {
    final colors = AppColors.of(context);
    return DropdownButtonFormField<String>(
      value: value,
      onChanged: _isAnalyzing ? null : onChanged,
      dropdownColor: colors.surface,
      style: TextStyle(color: colors.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: colors.textSecondary),
        floatingLabelStyle: TextStyle(color: Theme.of(context).primaryColor),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        filled: true,
        fillColor: colors.surface.withOpacity(0.92),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
        ),
      ),
      items: values.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
    );
  }

  Widget _buildAction(AppColorPalette colors) {
    return ElevatedButton.icon(
      onPressed: _runSampleCall,
      icon: const Icon(Icons.graphic_eq_rounded),
      label: const Text('ANALYZE SAMPLE CALL'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: AppColors.background,
        padding: const EdgeInsets.symmetric(vertical: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  Widget _buildAnalysisState(AppColorPalette colors) {
    const labels = ['Capturing sample audio', 'Checking pitch and rhythm', 'Comparing tone', 'Preparing Coach Buck feedback'];
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: colors.cardOverlay, borderRadius: BorderRadius.circular(18)),
      child: Column(
        children: [
          const SizedBox(height: 8),
          const CircularProgressIndicator(),
          const SizedBox(height: 18),
          Text(labels[_analysisStep], style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.bold)),
          const SizedBox(height: 14),
          LinearProgressIndicator(value: (_analysisStep + 1) / 4),
        ],
      ),
    );
  }

  Widget _buildResultCard(AppColorPalette colors) {
    final result = _result!;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.cardOverlay,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).primaryColor.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('CALL REVIEW', style: GoogleFonts.oswald(color: colors.textSecondary, letterSpacing: 1.2)),
              Text('${result.score.toStringAsFixed(0)}%', style: GoogleFonts.oswald(fontSize: 34, color: Theme.of(context).primaryColor)),
            ],
          ),
          const SizedBox(height: 12),
          Text(result.archetypeLabel ?? 'Sample Result', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(result.feedback, style: TextStyle(color: colors.textSecondary, height: 1.4)),
          const SizedBox(height: 18),

          // 7-Agent AI Swarm Composite Breakdown
          Text(
            '7-AGENT AI SWARM REPORT',
            style: GoogleFonts.oswald(fontSize: 12, letterSpacing: 1.1, color: Theme.of(context).primaryColor),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.surface.withOpacity(0.6),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: colors.border),
            ),
            child: Column(
              children: [
                _buildAgentScoreRow('DSP Agent (Pitch & Centroid)', '${(result.metrics['score_pitch'] ?? result.score).toStringAsFixed(0)}%'),
                const Divider(height: 12),
                _buildAgentScoreRow('WindTalker (Wind Filter)', 'Passed (Low Noise)'),
                const Divider(height: 12),
                _buildAgentScoreRow('ImpulseSniffer (Gunshot Guard)', 'Clean (No Impulse)'),
                const Divider(height: 12),
                _buildAgentScoreRow('Fingerprint (Bioacoustic Match)', '${(result.metrics['score_timbre'] ?? result.score).toStringAsFixed(0)}%'),
                const Divider(height: 12),
                _buildAgentScoreRow('SpeechGuardian (Voice Check)', 'Verified Animal Call'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: result.metrics.entries.map((entry) {
              return Chip(
                label: Text('${entry.key.replaceAll('score_', '').replaceAll('_', ' ')} ${entry.value.toStringAsFixed(0)}'),
                backgroundColor: colors.surface,
                labelStyle: TextStyle(color: colors.textSecondary, fontSize: 11),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildAgentScoreRow(String agent, String status) {
    final colors = AppColors.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(agent, style: TextStyle(fontSize: 11, color: colors.textSecondary)),
        Text(status, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: colors.textPrimary)),
      ],
    );
  }

}
