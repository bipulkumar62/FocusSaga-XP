import 'package:flutter_test/flutter_test.dart';
import 'package:focussaga_xp/features/characters/domain/owned_character.dart';

Map<String, dynamic> characterJson({
  int xp = 0,
  bool selected = false,
  int unlockedForms = 5,
  int? formUnlockedOrder = 5,
}) {
  return {
    'id': 'uc-1',
    'xp': xp,
    'is_selected': selected,
    'form_unlocked': formUnlockedOrder,
    'characters': {
      'id': 'char-1',
      'name': 'Ember',
      'description': 'A fiery companion.',
      'image_url': 'characters/ember.png',
      'is_starter': true,
      'character_forms': [
        for (var i = 1; i <= 5; i++)
          {
            'id': 'form-$i',
            'form_name': 'Ember Form $i',
            'form_order': i,
            'unlock_level': i * 10 - 9, // 1, 11, 21, 31, 41
            'image_url': 'characters/ember/f$i.png',
          },
      ],
    },
  };
}

void main() {
  group('OwnedCharacter', () {
    test('parses the join query payload', () {
      final c = OwnedCharacter.fromJson(characterJson());
      expect(c.id, 'uc-1');
      expect(c.characterId, 'char-1');
      expect(c.name, 'Ember');
      expect(c.forms.length, 5);
      expect(c.forms.last.formOrder, 5);
      expect(c.currentForm?.id, 'form-5');
    });

    test('level comes from XP (100 XP = level 2)', () {
      final c = OwnedCharacter.fromJson(characterJson(xp: 100));
      expect(c.level, 2);
      expect(c.xpIntoLevel, 0);
      expect(c.xpForNextLevel, 100);
      expect(c.levelProgress, 0);
    });

    test('XP bar is midway at 150 XP', () {
      final c = OwnedCharacter.fromJson(characterJson(xp: 150));
      expect(c.level, 2);
      expect(c.xpIntoLevel, 50);
      expect(c.levelProgress, 0.5);
    });

    test('forms unlock by level (level 1 -> only form 1)', () {
      final c = OwnedCharacter.fromJson(characterJson(xp: 0));
      expect(c.unlockedForms.length, 1);
      expect(c.unlockedForms.first.formOrder, 1);
      expect(c.isFormUnlocked(c.forms[0]), isTrue);
      expect(c.isFormUnlocked(c.forms[1]), isFalse);
    });

    test('level 21 unlocks forms 1-3', () {
      final c = OwnedCharacter.fromJson(characterJson(xp: 2000));
      expect(c.level, 21);
      expect(c.unlockedForms.length, 3);
    });

    test('currentForm falls back to highest unlocked when unset', () {
      final c = OwnedCharacter.fromJson(
        characterJson(xp: 2000, formUnlockedOrder: null),
      );
      expect(c.currentForm?.formOrder, 3);
    });

    test('max level pins the XP bar full', () {
      final c = OwnedCharacter.fromJson(characterJson(xp: 4900));
      expect(c.level, 50);
      expect(c.levelProgress, 1.0);
    });
  });
}
