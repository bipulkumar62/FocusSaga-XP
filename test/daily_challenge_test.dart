import 'package:flutter_test/flutter_test.dart';
import 'package:focussaga_xp/features/challenges/domain/daily_challenge.dart';

Map<String, dynamic> challengeJson({
  int progress = 0,
  bool completed = false,
  bool claimed = false,
}) {
  return {
    'id': 'udc-1',
    'title': 'Focus Sprint',
    'description': 'Study for 25 minutes today.',
    'metric': 'study_minutes',
    'target_value': 25,
    'progress': progress,
    'is_completed': completed,
    'claimed': claimed,
    'reward_coins': 20,
    'reward_xp': 10,
    'rank_points': 5,
  };
}

void main() {
  group('DailyChallenge.fromJson', () {
    test('parses the refresh payload', () {
      final c = DailyChallenge.fromJson(challengeJson(progress: 12));
      expect(c.id, 'udc-1');
      expect(c.metric, ChallengeMetric.studyMinutes);
      expect(c.targetValue, 25);
      expect(c.progress, 12);
      expect(c.rewardCoins, 20);
      expect(c.rewardXp, 10);
      expect(c.rankPoints, 5);
      expect(c.isCompleted, isFalse);
      expect(c.claimed, isFalse);
      expect(c.canClaim, isFalse);
    });

    test('progress ratio is clamped to 1.0', () {
      final c = DailyChallenge.fromJson(challengeJson(progress: 40));
      expect(c.progressRatio, 1.0);
    });

    test('canClaim requires completed and not claimed', () {
      final done = DailyChallenge.fromJson(challengeJson(progress: 25, completed: true));
      expect(done.canClaim, isTrue);
      expect(
        DailyChallenge.fromJson(challengeJson(progress: 25, completed: true, claimed: true)).canClaim,
        isFalse,
      );
      expect(
        DailyChallenge.fromJson(challengeJson(progress: 10)).canClaim,
        isFalse,
      );
    });
  });

  group('ChallengeMetric.fromApi', () {
    test('maps all five api values', () {
      expect(ChallengeMetric.fromApi('study_minutes'), ChallengeMetric.studyMinutes);
      expect(ChallengeMetric.fromApi('complete_sessions'), ChallengeMetric.completeSessions);
      expect(ChallengeMetric.fromApi('no_pause_session'), ChallengeMetric.noPauseSession);
      expect(ChallengeMetric.fromApi('level_up_character'), ChallengeMetric.levelUpCharacter);
      expect(ChallengeMetric.fromApi('use_background'), ChallengeMetric.useBackground);
    });
  });

  group('ChallengeClaim.fromJson', () {
    test('parses the claim payload', () {
      final claim = ChallengeClaim.fromJson({
        'reward_coins': 20,
        'reward_xp': 10,
        'rank_points': 5,
        'balance': 70,
        'character_level_after': 3,
        'levels_gained': 1,
        'level_up_coins': 20,
      });
      expect(claim.rewardCoins, 20);
      expect(claim.rewardXp, 10);
      expect(claim.balance, 70);
      expect(claim.levelsGained, 1);
      expect(claim.levelUpCoins, 20);
    });
  });
}
