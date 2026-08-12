import '../../progress/domain/progress_rules.dart';

/// One evolution form of a character (base form = form 1).
class CharacterForm {
  const CharacterForm({
    required this.id,
    required this.formName,
    required this.formOrder,
    required this.unlockLevel,
    this.imageUrl,
  });

  final String id;

  /// e.g. "Ember Sage" — display name of this evolution stage.
  final String formName;

  /// 1..5 — which stage of evolution this is.
  final int formOrder;

  /// Character level required to unlock this form.
  final int unlockLevel;

  final String? imageUrl;

  factory CharacterForm.fromJson(Map<String, dynamic> json) {
    return CharacterForm(
      id: json['id'] as String,
      formName: json['form_name'] as String? ?? 'Form ${json['form_order']}',
      formOrder: json['form_order'] as int,
      unlockLevel: json['unlock_level'] as int,
      imageUrl: json['image_url'] as String?,
    );
  }
}

/// A character owned by the current user (`user_characters` + `characters`).
class OwnedCharacter {
  const OwnedCharacter({
    required this.id,
    required this.characterId,
    required this.name,
    required this.description,
    this.classTitle,
    required this.isStarter,
    required this.isSelected,
    required this.xp,
    required this.formUnlockedOrder,
    required this.forms,
    this.imagePath,
    this.staticImagePath,
  });

  /// `user_characters.id` — the ownership row, not the character master id.
  final String id;
  final String characterId;
  final String name;
  final String description;

  /// Hero class, e.g. "Flame Ronin" (null before migration m28).
  final String? classTitle;

  final bool isStarter;
  final bool isSelected;
  final int xp;

  /// Which form (by evolution order) the user currently displays.
  final int? formUnlockedOrder;
  final String? imagePath;

  /// Hero art path (`characters/<slug>/preview.png`), null when missing.
  final String? staticImagePath;

  /// All 5 forms of this character, ordered 1..5.
  final List<CharacterForm> forms;

  // ---------- derived ----------

  int get level => XpRules.levelFromXp(xp);

  /// XP already earned inside the current level.
  int get xpIntoLevel => xp - XpRules.xpNeededForLevel(level);

  /// XP needed to complete the current level (0 at max level).
  int get xpForNextLevel =>
      level >= XpRules.maxLevel ? 0 : XpRules.xpPerLevel;

  /// 0.0..1.0 progress within the current level.
  double get levelProgress => xpForNextLevel == 0
      ? 1
      : (xpIntoLevel / xpForNextLevel).clamp(0.0, 1.0);

  /// All forms the current level unlocks.
  List<CharacterForm> get unlockedForms =>
      forms.where((f) => f.unlockLevel <= level).toList();

  /// The currently displayed form (falls back to the highest unlocked).
  CharacterForm? get currentForm {
    final picked = forms.where((f) => f.formOrder == formUnlockedOrder).toList();
    if (picked.isNotEmpty) return picked.first;
    return unlockedForms.isEmpty ? null : unlockedForms.last;
  }

  bool isFormUnlocked(CharacterForm form) => form.unlockLevel <= level;

  factory OwnedCharacter.fromJson(Map<String, dynamic> json) {
    final character = Map<String, dynamic>.from(json['characters'] as Map);
    final forms = (character['character_forms'] as List? ?? const [])
        .map((f) => CharacterForm.fromJson(Map<String, dynamic>.from(f as Map)))
        .toList()
      ..sort((a, b) => a.formOrder.compareTo(b.formOrder));
    return OwnedCharacter(
      id: json['id'] as String,
      characterId: character['id'] as String,
      name: character['name'] as String,
      description: character['description'] as String? ?? '',
      classTitle: character['class_title'] as String?,
      isStarter: character['is_starter'] as bool? ?? false,
      isSelected: json['is_selected'] as bool? ?? false,
      xp: json['xp'] as int? ?? 0,
      formUnlockedOrder: json['form_unlocked'] as int?,
      imagePath: character['image_url'] as String?,
      staticImagePath: character['static_image_path'] as String?,
      forms: forms,
    );
  }
}
