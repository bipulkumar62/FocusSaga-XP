-- ============================================================
-- Milestone 27: Flame character sprite paths
--
-- Characters get per-animation sprite sheet paths (local asset
-- paths; the sheets live in assets/characters/<name>/).
--   idle  = 6 frames, walk = 6, victory = 8, level_up = 10
--   frame size 128x128, horizontal strip, transparent PNG
-- static_image_path = neutral pose used as UI fallback art.
-- Characters without a sheet (null) fall back to a placeholder
-- tile with a clean static image in the app.
-- ============================================================

alter table public.characters
    add column if not exists sprite_idle_path text,
    add column if not exists sprite_walk_path text,
    add column if not exists sprite_victory_path text,
    add column if not exists sprite_level_up_path text,
    add column if not exists static_image_path text;

update public.characters
   set sprite_idle_path     = 'characters/' || lower(name) || '/idle.png',
       sprite_walk_path     = 'characters/' || lower(name) || '/walk.png',
       sprite_victory_path  = 'characters/' || lower(name) || '/victory.png',
       sprite_level_up_path = 'characters/' || lower(name) || '/level_up.png',
       static_image_path    = 'characters/' || lower(name) || '/static.png'
 where lower(name) in ('kairo', 'momo', 'mizu', 'yuki', 'hana');