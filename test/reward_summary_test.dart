import 'package:flutter_test/flutter_test.dart';
import 'package:focussaga_xp/features/progress/domain/reward_summary.dart';

void main() {
  group('RewardSummary.fromJson', () {
    test('parses the save_study_session jsonb payload', () {
      final summary = RewardSummary.fromJson({
        'actual_minutes': 25,
        'completed': true,
        'xp_earned': 30,
        'coins_earned': 40,
        'character_id': '11111111-1111-1111-1111-111111111111',
        'character_xp_before': 180,
        'character_xp_after': 210,
        'character_level_before': 2,
        'character_level_after': 4,
        'levels_gained': 2,
      });

      expect(summary.xpEarned, 30);
      expect(summary.coinsEarned, 40);
      expect(summary.characterLevelBefore, 2);
      expect(summary.characterLevelAfter, 4);
      expect(summary.levelsGained, 2);
      expect(summary.leveledUp, isTrue);
      expect(summary.characterXpAfter, 210);
    });

    test('reports a level-up for one cleared level', () {
      final summary = RewardSummary.fromJson({
        'actual_minutes': 50,
        'completed': true,
        'xp_earned': 60,
        'coins_earned': 20,
        'character_id': null,
        'character_xp_before': 99,
        'character_xp_after': 159,
        'character_level_before': 1,
        'character_level_after': 2,
        'levels_gained': 1,
      });

      expect(summary.leveledUp, isTrue);
      expect(summary.coinsEarned, 20);
    });
  });
}
