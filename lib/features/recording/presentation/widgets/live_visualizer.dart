import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:outcall/features/recording/domain/visualization_settings.dart';
import 'package:outcall/core/theme/app_colors.dart';
import 'package:outcall/features/recording/domain/audio_sample.dart';

class LiveVisualizer extends StatelessWidget {
  final List<AudioSample>? activeSamples;
  final List<double>? referencePattern;
  final List<List<double>>? referenceSpectrogram;
  final VisualizationMode mode;
  final Color color;
  final bool isRecording;
  final double? referenceAvgAmplitude; // Average amplitude of reference call
  final double referenceDurationSec;

  const LiveVisualizer({
    super.key,
    this.activeSamples,
    this.referencePattern,
    this.referenceSpectrogram,
    this.mode = VisualizationMode.waveform,
    this.color = Colors.green,
    this.isRecording = false,
    this.referenceAvgAmplitude,
    this.referenceDurationSec = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: SizedBox(
        height: 120,
        width: double.infinity,
        child: CustomPaint(
          painter: _CoachingWaveformPainter(
            activeSamples: activeSamples,
            referencePattern: referencePattern,
            referenceSpectrogram: referenceSpectrogram,
            mode: mode,
            color: color,
            isRecording: isRecording,
            referenceAvgAmplitude: referenceAvgAmplitude,
            referenceDurationSec: referenceDurationSec > 0 ? referenceDurationSec : 1.0,
          ),
        ),
      ),
    );
  }
}

class _CoachingWaveformPainter extends CustomPainter {
  final List<AudioSample>? activeSamples;
  final List<double>? referencePattern;
  final List<List<double>>? referenceSpectrogram;
  final VisualizationMode mode;
  final Color color;
  final bool isRecording;
  final double? referenceAvgAmplitude;
  final double referenceDurationSec;

  static const double _viewWindowSec = 5.0; // Show 5 seconds of audio horizontally
  static const int _dataPoints = 60;
  static const Color _refColor = Color(0xFFFF6D00);     // Safety orange for reference
  static const double _noiseFloor = 0.05;               // Very low threshold for rendering

  // Coaching colors
  static const Color _goodColor = AppColors.success;    // Bright teal-green — in zone
  static const Color _warmColor = AppColors.warning;    // Amber — close to zone
  static const Color _hotColor  = AppColors.error;    // Red — way off

  _CoachingWaveformPainter({
    this.activeSamples,
    this.referencePattern,
    this.referenceSpectrogram,
    required this.mode,
    required this.color,
    required this.isRecording,
    this.referenceAvgAmplitude,
    required this.referenceDurationSec,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double barGap = size.width / (_dataPoints * 3);
    final double barWidth = (size.width - (_dataPoints - 1) * barGap) / _dataPoints;
    final double centerY = size.height / 2;
    final double maxBarHeight = size.height * 0.85;

    // Determine visual time window
    double viewWindowStart = 0.0;
    
    if (activeSamples != null && activeSamples!.isNotEmpty) {
      final double firstTime = activeSamples!.first.timeSec;
      final double latestTime = activeSamples!.last.timeSec;
      
      if (firstTime < 0) {
        viewWindowStart = firstTime;
      }
      
      if (latestTime - viewWindowStart > _viewWindowSec) {
        viewWindowStart = latestTime - _viewWindowSec;
      }
    }
    
    final double viewWindowEnd = viewWindowStart + _viewWindowSec;

    // Sample data into _dataPoints bars mapped by time!
    final refSamples = _sampleReferencePattern(viewWindowStart, viewWindowEnd);
    final activeAmplitudes = _sampleActiveAmplitudes(viewWindowStart, viewWindowEnd);

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
        Paint()..color = _goodColor.withOpacity(0.06),
      );
      // Bottom half zone
      canvas.drawRect(
        Rect.fromLTRB(0, zoneLowYBottom, size.width, zoneHighYBottom),
        Paint()..color = _goodColor.withOpacity(0.06),
      );

      // Zone boundary lines (subtle dashed)
      final zonePaint = Paint()
        ..color = _goodColor.withOpacity(0.15)
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
        colors: [_refColor, _refColor.withOpacity(0.7)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    // Center line (dashed effect)
    final centerPaint = Paint()
      ..color = _goodColor.withOpacity(isRecording ? 0.3 : 0.1)
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
      if (i < refSamples.length) {
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
      if (i < activeAmplitudes.length) {
        final double activeVal = activeAmplitudes[i];
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
                ..color = barColor.withOpacity(0.12)
                ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0),
            );
          }

          // Main active bar with coaching gradient
          final activePaint = Paint()
            ..style = PaintingStyle.fill
            ..shader = LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [barColor, barColor.withOpacity(isRecording ? 0.5 : 0.15)],
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
              ..color = Colors.white.withOpacity(0.15)),
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

  List<double> _sampleReferencePattern(double startSec, double endSec) {
    if (referencePattern == null || referencePattern!.isEmpty || referenceDurationSec <= 0) {
      return List.filled(_dataPoints, 0.0);
    }
    return List.generate(_dataPoints, (i) {
      final double time = startSec + (endSec - startSec) * (i / (_dataPoints - 1));
      if (time < 0 || time > referenceDurationSec) return 0.0;
      
      final double rawIdx = (time / referenceDurationSec) * (referencePattern!.length - 1);
      final int idx = rawIdx.floor().clamp(0, referencePattern!.length - 1);
      return referencePattern![idx].clamp(0.0, 1.0);
    });
  }

  List<double> _sampleActiveAmplitudes(double startSec, double endSec) {
    if (activeSamples == null || activeSamples!.isEmpty) {
      return List.filled(_dataPoints, 0.0);
    }
    return List.generate(_dataPoints, (i) {
      final double time = startSec + (endSec - startSec) * (i / (_dataPoints - 1));
      
      AudioSample? closest;
      double minDiff = double.infinity;
      for (final s in activeSamples!) {
        final diff = (s.timeSec - time).abs();
        if (diff < minDiff) {
          minDiff = diff;
          closest = s;
        }
      }
      
      // A width of 5 secs / 60 points = 83ms per point.
      // Samples are ~50ms apart. 150ms diff tolerance is safe.
      if (closest == null || minDiff > 0.15) return 0.0;
      
      return closest.amplitude.clamp(0.0, 1.0);
    });
  }

  @override
  bool shouldRepaint(covariant _CoachingWaveformPainter oldDelegate) {
    return true; // We always rebuild and repaint when amplitudes update
  }
}
