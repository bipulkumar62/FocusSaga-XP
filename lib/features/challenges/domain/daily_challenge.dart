import 'package:flutter/material.dart';

/// The five challenge metrics.
enum ChallengeMetric {
  studyMinutes,
  completeSessions,
  noPauseSession,
  levelUpCharacter,
  useBackground;

  static ChallengeMetric fromApi(String value) => switch (value) {
        'study_minutes' => ChallengeMetric.studyMinutes,
        'complete_sessions' => ChallengeMetric.completeSessions,
        'no_pause_session' => ChallengeMetric.noPauseSession,
        'level_up_character' => ChallengeMetric.levelUpCharacter,
        'use_background' => ChallengeMetric.useBackground,
        _ => ChallengeMetric.studyMinutes,
      };

  String get label => switch (this) {
        ChallengeMetric.studyMinutes => 'Study minutes',
        ChallengeMetric.completeSessions => 'Completed sessions',
        ChallengeMetric.noPauseSession => 'No-pause sessions',
        ChallengeMetric.levelUpCharacter => 'Character level-ups',
        ChallengeMetric.useBackground => 'Background usage',
      };

  IconData get icon => switch (this) {
        ChallengeMetric.studyMinutes => Icons.timer_outlined,
        ChallengeMetric.completeSessions => Icons.check_circle_outline,
        ChallengeMetric.noPauseSession => Icons.pause_circle_outline,
        ChallengeMetric.levelUpCharacter => Icons.trending_up_rounded,
        ChallengeMetric.useBackground => Icons.wallpaper_rounded,
      };
}

/// One of today's challenges (`user_daily_challenges` + template).
class DailyChallenge {
  const DailyChallenge({
    required this.id,
    required this.title,
    required this.description,
    required this.metric,
    required this.targetValue,
    required this.progress,
    required this.isCompleted,
    required this.claimed,
    required this.rewardCoins,
    required this.rewardXp,
    required this.rankPoints,
  });

  /// `user_daily_challenges.id` — used by claim_challenge_reward.
  final String id;
  final String title;
  final String description;
  final ChallengeMetric metric;
  final int targetValue;
  final int progress;
  final bool isCompleted;
  final bool claimed;
  final int rewardCoins;
  final int rewardXp;
  final int rankPoints;

  /// 0.0..1.0 for the progress bar.
  double get progressRatio =>
      (progress / targetValue).clamp(0.0, 1.0);

  /// Claim is only possible once, and only when complete.
  bool get canClaim => isCompleted && !claimed;

  factory DailyChallenge.fromJson(Map<String, dynamic> json) {
    return DailyChallenge(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      metric: ChallengeMetric.fromApi(json['metric'] as String),
      targetValue: json['target_value'] as int,
      progress: json['progress'] as int,
      isCompleted: json['is_completed'] as bool? ?? false,
      claimed: json['claimed'] as bool? ?? false,
      rewardCoins: json['reward_coins'] as int? ?? 0,
      rewardXp: json['reward_xp'] as int? ?? 0,
      rankPoints: json['rank_points'] as int? ?? 0,
    );
  }
}

/// Result of `claim_challenge_reward`.
class ChallengeClaim {
  const ChallengeClaim({
    required this.rewardCoins,
    required this.rewardXp,
    required this.rankPoints,
    required this.balance,
    this.characterLevelAfter,
    required this.levelsGained,
    required this.levelUpCoins,
  });

  final int rewardCoins;
  final int rewardXp;
  final int rankPoints;

  /// New coin balance after claiming.
  final int balance;

  /// Level of the equipped character after the XP was applied.
  final int? characterLevelAfter;

  /// Levels cleared by the reward XP (0 = none).
  final int levelsGained;

  /// Extra coins from those level-ups (20 per level).
  final int levelUpCoins;

  factory ChallengeClaim.fromJson(Map<String, dynamic> json) {
    return ChallengeClaim(
      rewardCoins: json['reward_coins'] as int? ?? 0,
      rewardXp: json['reward_xp'] as int? ?? 0,
      rankPoints: json['rank_points'] as int? ?? 0,
      balance: json['balance'] as int? ?? 0,
      characterLevelAfter: json['character_level_after'] as int?,
      levelsGained: json['levels_gained'] as int? ?? 0,
      levelUpCoins: json['level_up_coins'] as int? ?? 0,
    );
  }
}
