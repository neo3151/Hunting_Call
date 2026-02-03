# 🔌 Integration Guide - Comprehensive Analytics

## Files to Update

To integrate the comprehensive analytics system, you need to update these files:

---

## 1. Update Dependency Injection

**File:** `lib/injection_container.dart`

### Change:
```dart
// OLD - Simple frequency analyzer
sl.registerLazySingleton<FrequencyAnalyzer>(() => FFTEAFrequencyAnalyzer());
```

### To:
```dart
// NEW - Comprehensive audio analyzer
sl.registerLazySingleton<FrequencyAnalyzer>(() => ComprehensiveAudioAnalyzer());
```

### Add import:
```dart
import 'features/analysis/data/comprehensive_audio_analyzer.dart';
```

---

## 2. Update Rating Service

**File:** `lib/features/analysis/data/real_rating_service.dart`

### Add method to get full analysis:
```dart
import '../domain/audio_analysis_model.dart';
import 'comprehensive_audio_analyzer.dart';

class RealRatingService implements RatingService {
  final FrequencyAnalyzer analyzer;
  final ProfileRepository profileRepository;

  RealRatingService({required this.analyzer, required this.profileRepository});

  // NEW: Get comprehensive analysis
  Future<AudioAnalysis?> getAudioAnalysis(String audioPath) async {
    if (analyzer is ComprehensiveAudioAnalyzer) {
      return await (analyzer as ComprehensiveAudioAnalyzer).analyzeAudio(audioPath);
    }
    return null;
  }

  @override
  Future<RatingResult> rateCall(String userId, String audioPath, String animalType) async {
    // Existing code...
    final detectedPitch = await analyzer.getDominantFrequency(audioPath);
    
    // NEW: Get comprehensive analysis if available
    AudioAnalysis? fullAnalysis = await getAudioAnalysis(audioPath);
    
    // Use fullAnalysis.dominantFrequencyHz if available
    // Otherwise fall back to detectedPitch
    
    // ... rest of existing rating logic
  }
}
```

---

## 3. Update Rating Result Model

**File:** `lib/features/rating/domain/rating_model.dart`

### Add optional analytics field:
```dart
import '../../analysis/domain/audio_analysis_model.dart';

@JsonSerializable()
class RatingResult {
  final double score;
  final String feedback;
  final double pitchHz;
  final Map<String, double> metrics;
  
  // NEW: Optional comprehensive analytics
  @JsonKey(includeIfNull: false)
  final AudioAnalysis? audioAnalysis;

  RatingResult({
    required this.score,
    required this.feedback,
    required this.pitchHz,
    required this.metrics,
    this.audioAnalysis, // NEW
  });

  factory RatingResult.fromJson(Map<String, dynamic> json) => _$RatingResultFromJson(json);
  Map<String, dynamic> toJson() => _$RatingResultToJson(this);
}
```

### Regenerate code:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

---

## 4. Update Rating Screen

**File:** `lib/features/rating/presentation/rating_screen.dart`

### Add analytics display:
```dart
import '../../analysis/presentation/audio_analytics_display.dart';
import '../../analysis/domain/audio_analysis_model.dart';

// In the build method, after existing content:
// Add expandable analytics section

if (result?.audioAnalysis != null) ...[
  const SizedBox(height: 32),
  
  _buildExpandableSection(
    title: "DETAILED ANALYTICS",
    icon: Icons.analytics_outlined,
    content: AudioAnalyticsDisplay(
      analysis: result!.audioAnalysis!,
    ),
  ),
],
```

### Add expandable section method:
```dart
Widget _buildExpandableSection({
  required String title,
  required IconData icon,
  required Widget content,
}) {
  return ClipRRect(
    borderRadius: BorderRadius.circular(16),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.all(20),
        childrenPadding: const EdgeInsets.all(20),
        backgroundColor: Colors.white.withValues(alpha: 0.05),
        collapsedBackgroundColor: Colors.white.withValues(alpha: 0.05),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        collapsedShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        leading: Icon(icon, color: Colors.greenAccent),
        title: Text(
          title,
          style: GoogleFonts.oswald(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 1.0,
          ),
        ),
        iconColor: Colors.white,
        collapsedIconColor: Colors.white70,
        children: [content],
      ),
    ),
  );
}
```

---

## 5. Update Rating Service to Include Analytics

**File:** `lib/features/analysis/data/real_rating_service.dart`

### Complete update:
```dart
@override
Future<RatingResult> rateCall(String userId, String audioPath, String animalType) async {
  // 1. Get reference call
  final reference = MockReferenceDatabase.getById(animalType);

  // 2. Get comprehensive analysis
  AudioAnalysis? fullAnalysis;
  double detectedPitch = 0.0;
  
  if (analyzer is ComprehensiveAudioAnalyzer) {
    fullAnalysis = await (analyzer as ComprehensiveAudioAnalyzer).analyzeAudio(audioPath);
    detectedPitch = fullAnalysis.dominantFrequencyHz;
  } else {
    detectedPitch = await analyzer.getDominantFrequency(audioPath);
  }
  
  // 3. Calculate duration (existing code)
  double detectedDuration = 0.0;
  try {
    final file = File(audioPath);
    final bytes = await file.readAsBytes();
    if (bytes.length > 44) {
      final ByteData view = bytes.buffer.asByteData();
      int sampleRate = 44100;
      if (bytes.length >= 28) {
        sampleRate = view.getUint32(24, Endian.little);
      }
      detectedDuration = (bytes.length - 44) / (sampleRate * 1 * 2);
    }
  } catch (e) {
    debugPrint("Duration Analysis Error: $e");
    detectedDuration = reference.idealDurationSec;
  }

  // 4. Calculate score (existing code)
  final pitchDiff = (detectedPitch - reference.idealPitchHz).abs();
  final durationDiff = (detectedDuration - reference.idealDurationSec).abs();

  double pitchScore = 100.0;
  if (pitchDiff > reference.tolerancePitch) {
    pitchScore = max(0, 100 - (pitchDiff - reference.tolerancePitch));
  }

  double durationScore = 100.0;
  if (durationDiff > reference.toleranceDuration) {
    durationScore = max(0, 100 - ((durationDiff - reference.toleranceDuration) * 200));
  }

  final totalScore = (pitchScore * 0.6) + (durationScore * 0.4);

  // 5. Generate feedback (existing code)
  String feedback = "";
  if (totalScore > 85) {
    feedback = "Outstanding! You sound just like a ${reference.animalName}.";
  } else {
    if (pitchScore < durationScore) {
      if (detectedPitch > reference.idealPitchHz) {
        feedback = "Too High! Lower your pitch by approx ${(detectedPitch - reference.idealPitchHz).toInt()}Hz.";
      } else {
        feedback = "Too Low! Raise your pitch by approx ${(reference.idealPitchHz - detectedPitch).toInt()}Hz.";
      }
    } else {
      if (durationDiff > reference.toleranceDuration) {
        if (detectedDuration > reference.idealDurationSec) {
          feedback = "Too Long! Shorten the call by ${(detectedDuration - reference.idealDurationSec).toStringAsFixed(1)}s.";
        } else {
          feedback = "Too Short! Hold the call for ${(reference.idealDurationSec - detectedDuration).toStringAsFixed(1)}s longer.";
        }
      } else {
        feedback = "Pitch is good, but try to be more consistent.";
      }
    }
  }

  // 6. Create result with analytics
  final result = RatingResult(
    score: totalScore,
    feedback: feedback,
    pitchHz: detectedPitch,
    metrics: {
      "Pitch (Hz)": detectedPitch,
      "Target Pitch": reference.idealPitchHz,
      "Duration (s)": detectedDuration,
    },
    audioAnalysis: fullAnalysis, // NEW: Include comprehensive analytics
  );

  // 7. Save to history
  await profileRepository.saveResultForUser(userId, result, animalType);
  
  return result;
}
```

---

## 6. Generate JSON Serialization Code

The `AudioAnalysis` model needs code generation:

### Create the .g.dart file stub:
**File:** `lib/features/analysis/domain/audio_analysis_model.g.dart`

```dart
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'audio_analysis_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AudioAnalysis _$AudioAnalysisFromJson(Map<String, dynamic> json) =>
    AudioAnalysis(
      dominantFrequencyHz: (json['dominantFrequencyHz'] as num).toDouble(),
      averageFrequencyHz: (json['averageFrequencyHz'] as num).toDouble(),
      frequencyPeaks: (json['frequencyPeaks'] as List<dynamic>)
          .map((e) => (e as num).toDouble())
          .toList(),
      pitchStability: (json['pitchStability'] as num).toDouble(),
      averageVolume: (json['averageVolume'] as num).toDouble(),
      peakVolume: (json['peakVolume'] as num).toDouble(),
      volumeConsistency: (json['volumeConsistency'] as num).toDouble(),
      toneClarity: (json['toneClarity'] as num).toDouble(),
      harmonicRichness: (json['harmonicRichness'] as num).toDouble(),
      harmonics: Map<String, double>.from(json['harmonics'] as Map),
      brightness: (json['brightness'] as num).toDouble(),
      warmth: (json['warmth'] as num).toDouble(),
      nasality: (json['nasality'] as num).toDouble(),
      spectralCentroid: (json['spectralCentroid'] as List<dynamic>)
          .map((e) => (e as num).toDouble())
          .toList(),
      totalDurationSec: (json['totalDurationSec'] as num).toDouble(),
      activeDurationSec: (json['activeDurationSec'] as num).toDouble(),
      silenceDurationSec: (json['silenceDurationSec'] as num).toDouble(),
      tempo: (json['tempo'] as num).toDouble(),
      pulseTimes: (json['pulseTimes'] as List<dynamic>)
          .map((e) => (e as num).toDouble())
          .toList(),
      rhythmRegularity: (json['rhythmRegularity'] as num).toDouble(),
      isPulsedCall: json['isPulsedCall'] as bool,
      callQualityScore: (json['callQualityScore'] as num).toDouble(),
      noiseLevel: (json['noiseLevel'] as num).toDouble(),
    );

Map<String, dynamic> _$AudioAnalysisToJson(AudioAnalysis instance) =>
    <String, dynamic>{
      'dominantFrequencyHz': instance.dominantFrequencyHz,
      'averageFrequencyHz': instance.averageFrequencyHz,
      'frequencyPeaks': instance.frequencyPeaks,
      'pitchStability': instance.pitchStability,
      'averageVolume': instance.averageVolume,
      'peakVolume': instance.peakVolume,
      'volumeConsistency': instance.volumeConsistency,
      'toneClarity': instance.toneClarity,
      'harmonicRichness': instance.harmonicRichness,
      'harmonics': instance.harmonics,
      'brightness': instance.brightness,
      'warmth': instance.warmth,
      'nasality': instance.nasality,
      'spectralCentroid': instance.spectralCentroid,
      'totalDurationSec': instance.totalDurationSec,
      'activeDurationSec': instance.activeDurationSec,
      'silenceDurationSec': instance.silenceDurationSec,
      'tempo': instance.tempo,
      'pulseTimes': instance.pulseTimes,
      'rhythmRegularity': instance.rhythmRegularity,
      'isPulsedCall': instance.isPulsedCall,
      'callQualityScore': instance.callQualityScore,
      'noiseLevel': instance.noiseLevel,
    };
```

### Run build runner:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

---

## 7. Optional: Add Analytics Toggle

Some users might want simple vs detailed view. Add a toggle:

```dart
// In rating_screen.dart state
bool showDetailedAnalytics = false;

// Add toggle button
IconButton(
  icon: Icon(showDetailedAnalytics ? Icons.analytics : Icons.analytics_outlined),
  onPressed: () => setState(() => showDetailedAnalytics = !showDetailedAnalytics),
  tooltip: showDetailedAnalytics ? "Hide Details" : "Show Details",
)

// Conditionally show
if (showDetailedAnalytics && result?.audioAnalysis != null) {
  AudioAnalyticsDisplay(analysis: result!.audioAnalysis!)
}
```

---

## 📋 Complete Integration Checklist

- [ ] Add `audio_analysis_model.dart` to project
- [ ] Add `comprehensive_audio_analyzer.dart` to project
- [ ] Add `audio_analytics_display.dart` to project
- [ ] Update `injection_container.dart` - register new analyzer
- [ ] Update `rating_model.dart` - add audioAnalysis field
- [ ] Update `real_rating_service.dart` - include analytics in result
- [ ] Update `rating_screen.dart` - display analytics
- [ ] Run `flutter pub run build_runner build`
- [ ] Test with sample recording
- [ ] Verify all metrics display correctly

---

## 🧪 Testing

### Test Each Metric Category:

1. **Pitch**: Record steady tone vs warbling tone
2. **Volume**: Record quiet vs loud vs clipping
3. **Tone**: Record clean call vs noisy environment
4. **Timbre**: Compare different animals (duck vs elk)
5. **Duration**: Record short, medium, long calls
6. **Rhythm**: Record pulsed (turkey yelp) vs continuous (elk bugle)

### Expected Results:

- Duck greeting: High pitch stability, moderate brightness
- Elk bugle: High brightness, low warmth, continuous
- Turkey yelp: Pulsed call detected, regular rhythm
- Buck grunt: High warmth, low brightness, short duration

---

## 🎯 Success Verification

After integration, verify:
- ✅ Recordings analyze without errors
- ✅ All 6 metric categories display
- ✅ Values are reasonable (not all 0 or 100)
- ✅ Color coding reflects quality
- ✅ Expandable section works
- ✅ Performance is acceptable (<2 seconds analysis)

---

## 🐛 Troubleshooting

### Issue: Analysis returns all zeros
**Fix**: Check that audio file is valid WAV format with proper header

### Issue: Build runner fails
**Fix**: Run `flutter clean` then `flutter pub get` then build_runner

### Issue: Metrics don't display
**Fix**: Verify `audioAnalysis` is not null in RatingResult

### Issue: App crashes during analysis
**Fix**: Check that chunk sizes don't exceed sample length

---

**Version**: 1.1.0
**Integration Time**: ~30 minutes
**Complexity**: Medium
