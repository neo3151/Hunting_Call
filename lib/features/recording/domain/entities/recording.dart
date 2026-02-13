/// Domain entity for a recorded audio session
class Recording {
  final String id;
  final String userId;
  final String animalId;
  final String audioPath;
  final DateTime recordedAt;
  final Duration duration;
  final double? score;
  
  const Recording({
    required this.id,
    required this.userId,
    required this.animalId,
    required this.audioPath,
    required this.recordedAt,
    required this.duration,
    this.score,
  });
  
  Recording copyWith({
    String? id,
    String? userId,
    String? animalId,
    String? audioPath,
    DateTime? recordedAt,
    Duration? duration,
    double? score,
  }) {
    return Recording(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      animalId: animalId ?? this.animalId,
      audioPath: audioPath ?? this.audioPath,
      recordedAt: recordedAt ?? this.recordedAt,
      duration: duration ?? this.duration,
      score: score ?? this.score,
    );
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Recording && other.id == id;
  }
  
  @override
  int get hashCode => id.hashCode;
  
  @override
  String toString() {
    return 'Recording(id: $id, animalId: $animalId, duration: ${duration.inSeconds}s, score: $score)';
  }
}
