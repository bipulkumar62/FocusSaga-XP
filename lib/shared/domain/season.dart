import 'package:flutter/material.dart';

/// The seven animated seasons of FocusSaga XP.
///
/// Seasons are the global app background. Exactly one is equipped at a time;
/// the equipped one lives in `user_inventory` (item_type = 'background') and
/// maps to a [SeasonType] through the `effect_type` column, so the app never
/// depends on database UUIDs.
enum SeasonType {
  forestMorning(
    effect: 'forest',
    slug: 'forest-morning',
    name: 'Forest Morning',
    description: 'Soft green trees, blurred blue mountains and gently '
        'falling leaves. The calm default.',
    priceCoins: 0,
    rarity: 'Common',
    unlockOrder: 1,
    isStarter: true,
    accent: Color(0xFF6B9E8F),
    skyTop: Color(0xFFBBDEF5),
    skyBottom: Color(0xFFE9F5EA),
  ),
  rainyWindow(
    effect: 'rain',
    slug: 'rainy-window',
    name: 'Rainy Window',
    description: 'A quiet rainy window with slow raindrops, soft window '
        'blur and a deep blue dusk.',
    priceCoins: 350,
    rarity: 'Common',
    unlockOrder: 2,
    isStarter: false,
    accent: Color(0xFF7A9CC6),
    skyTop: Color(0xFF2E4057),
    skyBottom: Color(0xFF1B2430),
  ),
  snowPine(
    effect: 'snow',
    slug: 'snow-pine',
    name: 'Snow Pine',
    description: 'Pine trees under blurred snowy mountains with drifting '
        'snow in a calm white-blue palette.',
    priceCoins: 700,
    rarity: 'Uncommon',
    unlockOrder: 3,
    isStarter: false,
    accent: Color(0xFFA8C6E8),
    skyTop: Color(0xFFDCE9F5),
    skyBottom: Color(0xFFF4F8FC),
  ),
  sunsetGarden(
    effect: 'sunset',
    slug: 'sunset-garden',
    name: 'Sunset Garden',
    description: 'Warm orange-pink sky, garden silhouettes and slowly '
        'floating petals.',
    priceCoins: 1100,
    rarity: 'Rare',
    unlockOrder: 4,
    isStarter: false,
    accent: Color(0xFFE8876E),
    skyTop: Color(0xFFFFB37E),
    skyBottom: Color(0xFFFFE8CF),
  ),
  neonNight(
    effect: 'neon',
    slug: 'neon-night',
    name: 'Neon Night',
    description: 'A dark purple-blue city blur with subtly glowing '
        'particles. A premium focus mood.',
    priceCoins: 1600,
    rarity: 'Rare',
    unlockOrder: 5,
    isStarter: false,
    accent: Color(0xFF7C6FF0),
    skyTop: Color(0xFF1A1533),
    skyBottom: Color(0xFF2A1E4E),
  ),
  cherryBlossom(
    effect: 'cherry',
    slug: 'cherry-blossom',
    name: 'Cherry Blossom',
    description: 'Pastel pink trees and falling blossom petals in soft '
        'spring air.',
    priceCoins: 2200,
    rarity: 'Epic',
    unlockOrder: 6,
    isStarter: false,
    accent: Color(0xFFF2A0BE),
    skyTop: Color(0xFFFFE3EE),
    skyBottom: Color(0xFFFFF7FA),
  ),
  celestialAurora(
    effect: 'aurora',
    slug: 'celestial-aurora',
    name: 'Celestial Aurora',
    description: 'The legendary finale: an aurora sky with glowing '
        'particles and distant cosmic mountains.',
    priceCoins: 5000,
    rarity: 'Legendary',
    unlockOrder: 7,
    isStarter: false,
    accent: Color(0xFF5FE3B8),
    skyTop: Color(0xFF0B1026),
    skyBottom: Color(0xFF141B3C),
  );

  const SeasonType({
    required this.effect,
    required this.slug,
    required this.name,
    required this.description,
    required this.priceCoins,
    required this.rarity,
    required this.unlockOrder,
    required this.isStarter,
    required this.accent,
    required this.skyTop,
    required this.skyBottom,
  });

  /// `backgrounds.effect_type` in the database.
  final String effect;

  /// Asset slug: art lives at `assets/backgrounds/<slug>/preview.png`.
  final String slug;

  final String name;
  final String description;
  final int priceCoins;
  final String rarity;
  final int unlockOrder;
  final bool isStarter;

  /// Theme color used for chips, glows and fallback preview tiles.
  final Color accent;

  /// Top/bottom colors of the animated sky gradient.
  final Color skyTop;
  final Color skyBottom;

  /// Static store preview (never animated — only the equipped season is).
  String get previewAsset => 'backgrounds/$slug/preview.png';

  /// Fallback when nothing is equipped or the mapping fails.
  static SeasonType get fallback => SeasonType.forestMorning;

  /// Maps a `backgrounds.effect_type` value to a season, or null.
  static SeasonType? fromEffect(String? effect) {
    if (effect == null) return null;
    for (final season in values) {
      if (season.effect == effect) return season;
    }
    return null;
  }

  /// Sorted cheapest → most expensive (default first).
  static List<SeasonType> get inUnlockOrder =>
      [...values]..sort((a, b) => a.unlockOrder.compareTo(b.unlockOrder));
}
