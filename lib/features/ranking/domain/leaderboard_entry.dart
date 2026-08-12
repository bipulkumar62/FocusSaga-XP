/// Row of the `daily_leaderboard` / `weekly_leaderboard` views.
class LeaderboardEntry {
  const LeaderboardEntry({
    required this.userId,
    this.displayName,
    this.avatarUrl,
    required this.profileLevel,
    required this.focusedMinutes,
    required this.challengeBonus,
    required this.streakDays,
    required this.streakBonus,
    required this.rankPoints,
  });

  final String userId;
  final String? displayName;
  final String? avatarUrl;
  final int profileLevel;
  final int focusedMinutes;
  final int challengeBonus;
  final int streakDays;
  final int streakBonus;
  final int rankPoints;

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      userId: json['user_id'] as String,
      displayName: json['display_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      profileLevel: (json['profile_level'] as num?)?.toInt() ?? 1,
      focusedMinutes: (json['focused_minutes'] as num?)?.toInt() ?? 0,
      challengeBonus: (json['challenge_bonus'] as num?)?.toInt() ?? 0,
      streakDays: (json['streak_days'] as num?)?.toInt() ?? 0,
      streakBonus: (json['streak_bonus'] as num?)?.toInt() ?? 0,
      rankPoints: (json['rank_points'] as num?)?.toInt() ?? 0,
    );
  }
}
