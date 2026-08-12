import 'package:flutter_test/flutter_test.dart';
import 'package:focussaga_xp/features/progress/domain/progress_rules.dart';

void main() {
  group('XpRules.xpForSession', () {
    test('1 actual minute = 1 XP', () {
      expect(XpRules.xpForSession(actualMinutes: 1, completed: false), 1);
    });

    test('early finish: no bonus (25 min -> 25 XP)', () {
      expect(XpRules.xpForSession(actualMinutes: 25, completed: false), 25);
    });

    test('full completion: +20% bonus (25 min -> 30 XP)', () {
      expect(XpRules.xpForSession(actualMinutes: 25, completed: true), 30);
    });

    test('full completion: +20% (50 min -> 60 XP)', () {
      expect(XpRules.xpForSession(actualMinutes: 50, completed: true), 60);
    });

    test('2h full completion (120 min -> 144 XP)', () {
      expect(XpRules.xpForSession(actualMinutes: 120, completed: true), 144);
    });

    test('rounds the 20% bonus (1 min completed -> 1 XP)', () {
      // 1 * 1.2 = 1.2 -> rounds to 1
      expect(XpRules.xpForSession(actualMinutes: 1, completed: true), 1);
    });

    test('5 min completed rounds up (5 * 1.2 = 6)', () {
      expect(XpRules.xpForSession(actualMinutes: 5, completed: true), 6);
    });

    test('zero minutes -> zero XP', () {
      expect(XpRules.xpForSession(actualMinutes: 0, completed: true), 0);
    });
  });

  group('XpRules.levelFromXp', () {
    test('starts at level 1', () {
      expect(XpRules.levelFromXp(0), 1);
    });

    test('below first threshold stays level 1 (99 XP)', () {
      expect(XpRules.levelFromXp(99), 1);
    });

    test('100 XP -> level 2', () {
      expect(XpRules.levelFromXp(100), 2);
    });

    test('exactly 4900 XP -> level 50', () {
      expect(XpRules.levelFromXp(4900), 50);
    });

    test('clamps at level 50 (99999 XP)', () {
      expect(XpRules.levelFromXp(99999), 50);
    });
  });

  group('XpRules.xpNeededForLevel', () {
    test('level 1 needs 0 XP', () {
      expect(XpRules.xpNeededForLevel(1), 0);
    });

    test('level 50 needs 4900 XP', () {
      expect(XpRules.xpNeededForLevel(50), 4900);
    });
  });

  group('XpRules.coinsGained', () {
    test('one cleared level = +20 coins', () {
      expect(
        XpRules.coinsGained(beforeLevel: 1, afterLevel: 2),
        20,
      );
    });

    test('three cleared levels = +60 coins', () {
      expect(
        XpRules.coinsGained(beforeLevel: 2, afterLevel: 5),
        60,
      );
    });

    test('no level up -> no coins', () {
      expect(
        XpRules.coinsGained(beforeLevel: 7, afterLevel: 7),
        0,
      );
    });
  });

  group('end-to-end economy examples', () {
    test('new user (50 coins): first 25-min full session', () {
      final xp = XpRules.xpForSession(actualMinutes: 25, completed: true);
      expect(xp, 30); // 25 * 1.2
      expect(XpRules.levelFromXp(0), 1);
      expect(XpRules.levelFromXp(xp), 1); // 30 XP, no level up
      expect(
        XpRules.coinsGained(beforeLevel: 1, afterLevel: 1),
        0,
      ); // still 50 coins
    });

    test('three 50-min full sessions -> level 2 and +20 coins', () {
      var xp = 0;
      var level = XpRules.levelFromXp(xp);
      var coins = 50;
      for (var i = 0; i < 3; i++) {
        xp += XpRules.xpForSession(actualMinutes: 50, completed: true); // 60 each
        final nextLevel = XpRules.levelFromXp(xp);
        coins += XpRules.coinsGained(beforeLevel: level, afterLevel: nextLevel);
        level = nextLevel;
      }
      expect(xp, 180);
      expect(level, 2);
      expect(coins, 70);
    });
  });
}