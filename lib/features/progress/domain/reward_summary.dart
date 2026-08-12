/// Result of applying rewards for a finished focus session.
class RewardSummary {
  const RewardSummary({
    required this.actualMinutes,
    required this.completed,
    required this.xpEarned,
    required this.characterId,
    required this.characterXpBefore,
    required this.characterXpAfter,
    required this.characterLevelBefore,
    required this.characterLevelAfter,
    required this.levelsGained,
    required this.coinsEarned,
  });

  final int actualMinutes;
  final bool completed;

  /// XP awarded this session (incl. full-completion bonus).
  final int xpEarned;

  /// The character the XP was stored on (null if none was owned).
  final String? characterId;
  final int characterXpBefore;
  final int characterXpAfter;
  final int characterLevelBefore;
  final int characterLevelAfter;

  /// How many levels were cleared (0 if none).
  final int levelsGained;

  /// Coins added to the profile (20 per cleared level).
  final int coinsEarned;

  bool get leveledUp => levelsGained > 0;

  /// Parses the jsonb object returned by `save_study_session` (M15 RPC).
  factory RewardSummary.fromJson(Map<String, dynamic> json) {
    return RewardSummary(
      actualMinutes: json['actual_minutes'] as int,
      completed: json['completed'] as bool,
      xpEarned: json['xp_earned'] as int,
      characterId: json['character_id'] as String?,
      characterXpBefore: json['character_xp_before'] as int,
      characterXpAfter: json['character_xp_after'] as int,
      characterLevelBefore: json['character_level_before'] as int,
      characterLevelAfter: json['character_level_after'] as int,
      levelsGained: json['levels_gained'] as int,
      coinsEarned: json['coins_earned'] as int,
    );
  }
}
