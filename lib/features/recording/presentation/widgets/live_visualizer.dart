import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../domain/visualization_settings.dart';

class LiveVisualizer extends StatelessWidget {
  final List<double> amplitudes;
  final List<double>? referencePattern;
  final List<List<double>>? referenceSpectrogram;
  final VisualizationMode mode;
  final Color color;
  final bool isRecording;

  const LiveVisualizer({
    super.key,
    required this.amplitudes,
    this.referencePattern,
    this.referenceSpectrogram,
    this.mode = VisualizationMode.waveform,
    this.color = Colors.green,
    this.isRecording = false,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: SizedBox(
        height: 120,
        width: double.infinity,
        child: CustomPaint(
          painter: _OverlaidWaveformPainter(
            amplitudes: amplitudes,
            referencePattern: referencePattern,
            referenceSpectrogram: referenceSpectrogram,
            mode: mode,
            color: color,
            isRecording: isRecording,
          ),
        ),
      ),
    );
  }
}

class _OverlaidWaveformPainter extends CustomPainter {
  final List<double> amplitudes;
  final List<double>? referencePattern;
  final List<List<double>>? referenceSpectrogram;
  final VisualizationMode mode;
  final Color color;
  final bool isRecording;

  static const int _dataPoints = 60;
  static const Color _refColor = Color(0xFFFF6D00);     // Safety orange for reference
  static const double _noiseFloor = 0.15;               // Below this = silence (no bar)

  _OverlaidWaveformPainter({
    required this.amplitudes,
    this.referencePattern,
    this.referenceSpectrogram,
    required this.mode,
    required this.color,
    required this.isRecording,
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

    // Paints
    final refPaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [_refColor, _refColor.withValues(alpha: 0.7)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final activePaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xBB5FF7B6), Color(0x775FF7B6)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    // Center line (dashed effect)
    final centerPaint = Paint()
      ..color = const Color(0xFF5FF7B6).withValues(alpha: isRecording ? 0.3 : 0.1)
      ..strokeWidth = 1.0;
    
    // Draw subtle center dashed line
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

      // 2. Draw Active bar (narrower, on top, brighter)
      if (activeSamples != null && i < activeSamples.length) {
        final double activeVal = activeSamples[i];
        if (activeVal > _noiseFloor) {
          final double activeH = activeVal * maxBarHeight;

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
                ..color = const Color(0xFF5FF7B6).withValues(alpha: 0.12)
                ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0),
            );
          }

          // Main active bar
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
  bool shouldRepaint(covariant _OverlaidWaveformPainter oldDelegate) {
    return oldDelegate.amplitudes != amplitudes ||
        oldDelegate.referencePattern != referencePattern ||
        oldDelegate.mode != mode ||
        oldDelegate.isRecording != isRecording;
  }
}
