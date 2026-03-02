import 'package:flutter/material.dart';

/// Compute average amplitude from reference waveform, ignoring silence.
///
/// Values below 0.05 are treated as silence and excluded from the average.
double computeReferenceAverage(List<double>? waveform) {
  if (waveform == null || waveform.isEmpty) return 0.0;
  double sum = 0;
  int count = 0;
  for (final v in waveform) {
    if (v > 0.05) {
      sum += v;
      count++;
    }
  }
  return count > 0 ? sum / count : 0.0;
}

/// Returns coaching feedback based on current amplitude vs reference target.
///
/// Compares the average of the most recent [amplitudeBuffer] samples against
/// the [refAvg] to determine if the user is too quiet, too loud, or in range.
({String text, Color color}) getCoachingFeedback(
  List<double> amplitudeBuffer,
  double refAvg,
) {
  if (amplitudeBuffer.isEmpty || refAvg < 0.05) {
    return (text: '', color: Colors.transparent);
  }

  // Use the average of last 10 samples for stable feedback
  final recent = amplitudeBuffer.length > 10
      ? amplitudeBuffer.sublist(amplitudeBuffer.length - 10)
      : amplitudeBuffer;
  final currentAvg = recent.fold<double>(0.0, (a, b) => a + b) / recent.length;

  if (currentAvg < 0.02) return (text: '', color: Colors.transparent); // Silence

  final zoneLow = refAvg * 0.5;
  final zoneHigh = refAvg * 1.5;

  if (currentAvg >= zoneLow && currentAvg <= zoneHigh) {
    return (text: '🎯 IN RANGE', color: const Color(0xFF5FF7B6));
  } else if (currentAvg < zoneLow) {
    return (text: '🔇 TOO QUIET', color: const Color(0xFFFFD54F));
  } else {
    return (text: '📢 TOO LOUD', color: const Color(0xFFFF5252));
  }
}
