import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:hunting_calls_perfection/features/recording/domain/visualization_settings.dart';

class LiveVisualizer extends StatelessWidget {
  final List<double> amplitudes;
  final List<double>? referencePattern;
  final List<List<double>>? referenceSpectrogram;
  final VisualizationMode mode;
  final Color color;
  final bool isRecording;
  final double? referenceAvgAmplitude; // Average amplitude of reference call

  const LiveVisualizer({
    super.key,
    required this.amplitudes,
    this.referencePattern,
    this.referenceSpectrogram,
    this.mode = VisualizationMode.waveform,
    this.color = Colors.green,
    this.isRecording = false,
    this.referenceAvgAmplitude,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: SizedBox(
        height: 120,
        width: double.infinity,
        child: CustomPaint(
          painter: _CoachingWaveformPainter(
            amplitudes: amplitudes,
            referencePattern: referencePattern,
            referenceSpectrogram: referenceSpectrogram,
            mode: mode,
            color: color,
            isRecording: isRecording,
            referenceAvgAmplitude: referenceAvgAmplitude,
          ),
        ),
      ),
    );
  }
}

class _CoachingWaveformPainter extends CustomPainter {
  final List<double> amplitudes;
  final List<double>? referencePattern;
  final List<List<double>>? referenceSpectrogram;
  final VisualizationMode mode;
  final Color color;
  final bool isRecording;
  final double? referenceAvgAmplitude;

  static const int _dataPoints = 60;
  static const Color _refColor = Color(0xFFFF6D00);     // Safety orange for reference
  static const double _noiseFloor = 0.05;               // Very low threshold for rendering

  // Coaching colors
  static const Color _goodColor = Color(0xFF5FF7B6);    // Bright teal-green — in zone
  static const Color _warmColor = Color(0xFFFFD54F);    // Amber — close to zone
  static const Color _hotColor  = Color(0xFFFF5252);    // Red — way off

  _CoachingWaveformPainter({
    required this.amplitudes,
    this.referencePattern,
    this.referenceSpectrogram,
    required this.mode,
    required this.color,
    required this.isRecording,
    this.referenceAvgAmplitude,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double barGap = size.width / (_dataPoints * 3);
    final double barWidth = (size.width - (_dataPoints - 1) * barGap) / _dataPoints;
    final double centerY = size.height / 2;
    final double maxBarHeight = size.height * 0.85;

    // Sample data into _dataPoints bars
    final refSamples = _sampleData(referencePattern, _dataPoints);
    final activeSamples = _sampleData(amplitudes, _dataPoints);

    // Compute reference target zone (average ± tolerance)
    final double refAvg = referenceAvgAmplitude ?? _computeAverage(refSamples);
    final double zoneLow  = (refAvg * 0.5).clamp(0.0, 1.0);
    final double zoneHigh = (refAvg * 1.5).clamp(0.0, 1.0);

    // ─── Draw target zone band when recording ───
    if (isRecording && refAvg > 0.05) {
      final double zoneLowY  = centerY - (zoneLow * maxBarHeight / 2);
      final double zoneHighY = centerY - (zoneHigh * maxBarHeight / 2);
      final double zoneLowYBottom  = centerY + (zoneLow * maxBarHeight / 2);
      final double zoneHighYBottom = centerY + (zoneHigh * maxBarHeight / 2);

      // Top half zone
      canvas.drawRect(
        Rect.fromLTRB(0, zoneHighY, size.width, zoneLowY),
        Paint()..color = _goodColor.withValues(alpha: 0.06),
      );
      // Bottom half zone
      canvas.drawRect(
        Rect.fromLTRB(0, zoneLowYBottom, size.width, zoneHighYBottom),
        Paint()..color = _goodColor.withValues(alpha: 0.06),
      );

      // Zone boundary lines (subtle dashed)
      final zonePaint = Paint()
        ..color = _goodColor.withValues(alpha: 0.15)
        ..strokeWidth = 0.5;
      
      canvas.drawLine(Offset(0, zoneHighY), Offset(size.width, zoneHighY), zonePaint);
      canvas.drawLine(Offset(0, zoneHighYBottom), Offset(size.width, zoneHighYBottom), zonePaint);
    }

    // Paints for reference bars
    final refPaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [_refColor, _refColor.withValues(alpha: 0.7)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    // Center line (dashed effect)
    final centerPaint = Paint()
      ..color = _goodColor.withValues(alpha: isRecording ? 0.3 : 0.1)
      ..strokeWidth = 1.0;
    
    const double dashWidth = 4.0;
    const double dashGap = 3.0;
    double dx = 0;
    while (dx < size.width) {
      canvas.drawLine(
        Offset(dx, centerY),
        Offset(math.min(dx + dashWidth, size.width), centerY),
        centerPaint,
      );
      dx += dashWidth + dashGap;
    }

    for (int i = 0; i < _dataPoints; i++) {
      final double x = i * (barWidth + barGap);
      final double barCenterX = x + barWidth / 2;

      // 1. Draw Reference bar (wider, behind)
      if (refSamples != null && i < refSamples.length) {
        final double refVal = refSamples[i];
        if (refVal > _noiseFloor) {
          final double refH = refVal * maxBarHeight;
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromCenter(
                center: Offset(barCenterX, centerY),
                width: barWidth,
                height: refH.clamp(2.0, size.height),
              ),
              Radius.circular(barWidth / 2),
            ),
            refPaint,
          );
        }
      }

      // 2. Draw Active bar (narrower, on top) with coaching colors
      if (activeSamples != null && i < activeSamples.length) {
        final double activeVal = activeSamples[i];
        if (activeVal > _noiseFloor) {
          final double activeH = activeVal * maxBarHeight;

          // Determine coaching color based on proximity to target zone
          Color barColor;
          if (!isRecording || refAvg < 0.05) {
            barColor = _goodColor; // Not recording or no reference: default color
          } else {
            barColor = _getCoachingColor(activeVal, zoneLow, zoneHigh);
          }

          // Glow effect when recording
          if (isRecording && activeH > 4) {
            canvas.drawRRect(
              RRect.fromRectAndRadius(
                Rect.fromCenter(
                  center: Offset(barCenterX, centerY),
                  width: barWidth * 0.8,
                  height: activeH + 2,
                ),
                Radius.circular(barWidth / 3),
              ),
              Paint()
                ..style = PaintingStyle.fill
                ..color = barColor.withValues(alpha: 0.12)
                ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0),
            );
          }

          // Main active bar with coaching gradient
          final activePaint = Paint()
            ..style = PaintingStyle.fill
            ..shader = LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [barColor, barColor.withValues(alpha: isRecording ? 0.5 : 0.15)],
            ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromCenter(
                center: Offset(barCenterX, centerY),
                width: barWidth * 0.65,
                height: activeH.clamp(2.0, size.height),
              ),
              Radius.circular(barWidth / 3),
            ),
            isRecording ? activePaint : (Paint()
              ..style = PaintingStyle.fill
              ..color = Colors.white.withValues(alpha: 0.15)),
          );
        }
      }
    }
  }

  /// Returns coaching color based on how close the amplitude is to the target zone
  Color _getCoachingColor(double val, double zoneLow, double zoneHigh) {
    if (val >= zoneLow && val <= zoneHigh) {
      return _goodColor; // In the zone
    }
    // How far off are we?
    final double distFromZone;
    if (val < zoneLow) {
      distFromZone = (zoneLow - val) / zoneLow;
    } else {
      distFromZone = (val - zoneHigh) / (1.0 - zoneHigh).clamp(0.01, 1.0);
    }
    
    if (distFromZone < 0.4) {
      return _warmColor; // Close — amber
    }
    return _hotColor; // Way off — red
  }

  double _computeAverage(List<double>? data) {
    if (data == null || data.isEmpty) return 0.0;
    double sum = 0;
    int count = 0;
    for (final v in data) {
      if (v > _noiseFloor) {
        sum += v;
        count++;
      }
    }
    return count > 0 ? sum / count : 0.0;
  }

  List<double>? _sampleData(List<double>? data, int count) {
    if (data == null || data.isEmpty) return null;
    if (data.length <= count) {
      return [...data, ...List.filled(count - data.length, 0.0)];
    }
    final step = data.length / count;
    return List.generate(count, (i) {
      final idx = (i * step).floor().clamp(0, data.length - 1);
      return data[idx].clamp(0.0, 1.0);
    });
  }

  @override
  bool shouldRepaint(covariant _CoachingWaveformPainter oldDelegate) {
    return oldDelegate.amplitudes != amplitudes ||
        oldDelegate.referencePattern != referencePattern ||
        oldDelegate.mode != mode ||
        oldDelegate.isRecording != isRecording ||
        oldDelegate.referenceAvgAmplitude != referenceAvgAmplitude;
  }
}
