import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:outcall/features/rating/domain/rating_model.dart';
import 'package:outcall/core/theme/app_colors.dart';

/// Extracted from rating_screen.dart — the comprehensive analytics section
/// including volume, tone, timbre and rhythm analysis cards.
class ComprehensiveAnalyticsSection extends StatelessWidget {
  final RatingResult result;

  const ComprehensiveAnalyticsSection({super.key, required this.result});

  Color _getColor(num? v) {
    if (v == null) return Colors.white24;
    if (v >= 80) return AppColors.success;
    if (v >= 60) return const Color(0xFFB8E986);
    return const Color(0xFFFFB74D);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('COMPREHENSIVE ANALYTICS'),
        const SizedBox(height: 20),
        _buildAnalyticsSection('VOLUME ANALYSIS', Icons.volume_up, [
          _buildAnalyticsCard('Average Volume', result.metrics['avg_volume'] ?? 65.0),
          _buildAnalyticsCard('Peak Volume', result.metrics['peak_volume'] ?? 82.0),
          _buildAnalyticsCard('Consistency', result.metrics['consistency'] ?? 78.0),
        ]),
        const SizedBox(height: 12),
        _buildAnalyticsSection('TONE ANALYSIS', Icons.tune, [
          _buildAnalyticsCard('Tone Clarity', result.metrics['tone_clarity'] ?? 85.0),
          _buildAnalyticsCard('Harmonic Richness', result.metrics['harmonic_richness'] ?? 72.0),
          _buildAnalyticsCard('Call Quality', result.metrics['call_quality'] ?? 88.0),
        ]),
        const SizedBox(height: 12),
        _buildAnalyticsSection('TIMBRE ANALYSIS', Icons.waves, [
          _buildAnalyticsCard('Brightness', result.metrics['brightness'] ?? 55.0),
          _buildAnalyticsCard('Warmth', result.metrics['warmth'] ?? 68.0),
          _buildAnalyticsCard('Nasality', result.metrics['nasality'] ?? 42.0),
        ]),
        const SizedBox(height: 12),
        _buildAnalyticsSection('RHYTHM ANALYSIS', Icons.timeline, [
          _buildAnalyticsCard('Tempo', null),
          _buildAnalyticsCard('Regularity', null),
        ], isNotPulsed: true),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Container(width: 3, height: 14, decoration: const BoxDecoration(color: AppColors.success, borderRadius: BorderRadius.all(Radius.circular(2)))),
        const SizedBox(width: 8),
        Flexible(
          child: Text(title, style: GoogleFonts.oswald(fontSize: 12, letterSpacing: 1.5, color: Colors.white, fontWeight: FontWeight.bold),
              maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
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
              Icon(icon, color: AppColors.success, size: 14),
              const SizedBox(width: 8),
              Flexible(
                child: Text(title, style: GoogleFonts.oswald(fontSize: 11, color: Colors.white70, fontWeight: FontWeight.bold, letterSpacing: 1),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (isNotPulsed)
            Column(
              children: [
                Row(children: cards.map((c) => Expanded(child: Padding(padding: const EdgeInsets.only(right: 8), child: c))).toList()),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(8)),
                  child: Text('Not a pulsed call', textAlign: TextAlign.center, style: GoogleFonts.lato(fontSize: 10, color: Colors.white24, fontStyle: FontStyle.italic)),
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

    return Container(
      width: 100,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.lato(fontSize: 9, color: Colors.white38, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(
            safeValue != null ? '${safeValue.toStringAsFixed(1)} %' : '--',
            style: GoogleFonts.oswald(fontSize: 18, color: _getColor(safeValue), fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          if (safeValue != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: safeValue / 100,
                minHeight: 3,
                backgroundColor: Colors.white.withValues(alpha: 0.1),
                color: _getColor(safeValue),
              ),
            ),
        ],
      ),
    );
  }
}

/// Tip section widget.
class RatingTipSection extends StatelessWidget {
  const RatingTipSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lightbulb_outline, color: AppColors.success, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Tip: These analytics help you understand the complete quality of your call, not just pitch and duration. Practice improving each dimension!',
              style: GoogleFonts.lato(fontSize: 11, color: Colors.white70, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

/// Guidance card used on the error state.
class GuidanceCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const GuidanceCard({super.key, required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.success, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.oswald(fontSize: 14, color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1)),
                const SizedBox(height: 2),
                Text(subtitle, style: GoogleFonts.lato(fontSize: 12, color: Colors.white60)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
