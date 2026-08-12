import 'package:flutter/material.dart';

/// The four store categories.
enum StoreItemKind { character, background, timerSkin, rewardAnimation }

extension StoreItemKindX on StoreItemKind {
  /// Value used in `user_inventory.item_type` and the buy RPC.
  String get apiValue => switch (this) {
        StoreItemKind.character => 'character',
        StoreItemKind.background => 'background',
        StoreItemKind.timerSkin => 'timer_skin',
        StoreItemKind.rewardAnimation => 'reward_animation',
      };

  String get label => switch (this) {
        StoreItemKind.character => 'Characters',
        StoreItemKind.background => 'Seasons',
        StoreItemKind.timerSkin => 'Timer skins',
        StoreItemKind.rewardAnimation => 'Reward animations',
      };

  IconData get icon => switch (this) {
        StoreItemKind.character => Icons.sports_martial_arts_rounded,
        StoreItemKind.background => Icons.landscape_rounded,
        StoreItemKind.timerSkin => Icons.timer_rounded,
        StoreItemKind.rewardAnimation => Icons.auto_awesome_rounded,
      };
}

/// One purchasable/owned store item, enriched with the current user's
/// ownership state.
class StoreItem {
  const StoreItem({
    required this.kind,
    required this.id,
    required this.name,
    required this.description,
    this.imageUrl,
    required this.priceCoins,
    this.unlockLevel,
    required this.owned,
    required this.equipped,
    this.ownedRowId,
    this.classTitle,
    this.staticImagePath,
    this.effectType,
    this.rarity,
    this.previewAssetPath,
  });

  final StoreItemKind kind;

  /// Master-table id (`characters.id`, `backgrounds.id`, ...).
  final String id;
  final String name;
  final String description;
  final String? imageUrl;
  final int priceCoins;

  /// Player level required to buy (characters only; 1 = no gate).
  final int? unlockLevel;

  final bool owned;
  final bool equipped;

  /// `user_characters.id` when owned — needed by `equip_character`.
  final String? ownedRowId;

  /// Hero class, e.g. "Flame Ronin" (characters only; null before m28).
  final String? classTitle;

  /// Hero art path (`characters/<slug>/preview.png`), null when missing.
  final String? staticImagePath;

  /// `backgrounds.effect_type` — maps to the animated season (seasons only).
  final String? effectType;

  /// Display rarity, e.g. "Legendary" (seasons only).
  final String? rarity;

  /// Static preview asset (`backgrounds/<slug>/preview.png`, seasons only).
  final String? previewAssetPath;

  factory StoreItem.fromJson(
    Map<String, dynamic> json, {
    required StoreItemKind kind,
    required bool owned,
    required bool equipped,
    String? ownedRowId,
  }) {
    return StoreItem(
      kind: kind,
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      imageUrl: json['image_url'] as String?,
      priceCoins: json['price_coins'] as int? ?? 0,
      unlockLevel: json['unlock_level'] as int?,
      owned: owned,
      equipped: equipped,
      ownedRowId: ownedRowId,
      classTitle: json['class_title'] as String?,
      staticImagePath: json['static_image_path'] as String?,
      effectType: json['effect_type'] as String?,
      rarity: json['rarity'] as String?,
      previewAssetPath: json['preview_asset_path'] as String?,
    );
  }
}

/// Everything the store tab shows, for all four categories.
class StoreCatalog {
  const StoreCatalog({required this.items});

  final List<StoreItem> items;

  List<StoreItem> forKind(StoreItemKind kind) =>
      items.where((i) => i.kind == kind).toList();

  static const StoreCatalog empty = StoreCatalog(items: []);
}
