class LeaderboardEntry {
  final String userId;
  final String userName;
  final double score; // 0.0 - 1.0 (or 0-100)
  final DateTime timestamp;
  final String? profileImageUrl;

  LeaderboardEntry({
    required this.userId,
    required this.userName,
    required this.score,
    required this.timestamp,
    this.profileImageUrl,
  });

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'userName': userName,
      'score': score,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'profileImageUrl': profileImageUrl,
    };
  }

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      userId: json['userId'] as String,
      userName: json['userName'] as String,
      score: (json['score'] as num).toDouble(),
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp'] as int),
      profileImageUrl: json['profileImageUrl'] as String?,
    );
  }
}
