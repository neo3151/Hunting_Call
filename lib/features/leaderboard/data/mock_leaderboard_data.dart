class LeaderboardEntry {
  final int rank;
  final String username;
  final double score;
  final String animalType;

  LeaderboardEntry({
    required this.rank,
    required this.username,
    required this.score,
    required this.animalType,
  });
}

class LeaderboardService {
  static List<LeaderboardEntry> getDailyLeaders() {
    return [
      LeaderboardEntry(rank: 1, username: "DuckMaster77", score: 98.4, animalType: "Mallard"),
      LeaderboardEntry(rank: 2, username: "TurkeyTamer", score: 95.2, animalType: "Wild Turkey"),
      LeaderboardEntry(rank: 3, username: "WoodsWalker", score: 92.1, animalType: "Elk"),
      LeaderboardEntry(rank: 4, username: "MarshKing", score: 89.5, animalType: "Mallard"),
      LeaderboardEntry(rank: 5, username: "CoyoteWhisper", score: 88.0, animalType: "Coyote"),
    ];
  }

  static List<LeaderboardEntry> getAllTimeLeaders() {
    return [
      LeaderboardEntry(rank: 1, username: "LegendHunter", score: 99.9, animalType: "Multiple"),
      LeaderboardEntry(rank: 2, username: "CallMasterPro", score: 99.5, animalType: "Multiple"),
      LeaderboardEntry(rank: 3, username: "NatureVoice", score: 98.8, animalType: "Multiple"),
    ];
  }
}
