/// XP / level / coin economy rules.
///
/// - 1 actual focused minute = 1 XP
/// - full completion = +20% XP bonus
/// - characters have 50 levels, 100 XP per level (linear curve)
/// - every cleared level = +20 coins
abstract final class XpRules {
  static const int xpPerMinute = 1;
  static const double fullCompletionBonus = 0.20;
  static const int xpPerLevel = 100;
  static const int maxLevel = 50;
  static const int coinsPerLevelCleared = 20;

  /// Base XP from actual studied minutes (no bonus).
  static int baseXp({required int actualMinutes}) => actualMinutes * xpPerMinute;

  /// Total XP for a session.
  /// `completed` = the timer hit zero naturally.
  static int xpForSession({required int actualMinutes, required bool completed}) {
    final base = baseXp(actualMinutes: actualMinutes);
    if (!completed) return base;
    return (base * (1 + fullCompletionBonus)).round();
  }

  /// Level for a given amount of character XP (1..50).
  static int levelFromXp(int xp) {
    final level = xp ~/ xpPerLevel + 1;
    return level.clamp(1, maxLevel);
  }

  /// Cumulative XP required to *reach* [level].
  static int xpNeededForLevel(int level) => (level - 1) * xpPerLevel;

  /// Coins awarded for climbing from [beforeLevel] to [afterLevel].
  static int coinsGained({required int beforeLevel, required int afterLevel}) {
    final levels = afterLevel - beforeLevel;
    return levels > 0 ? levels * coinsPerLevelCleared : 0;
  }
}