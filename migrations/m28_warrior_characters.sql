-- m28: Warrior character overhaul.
--
-- Replaces the animal mascot roster with the six original dark-fantasy
-- warriors (Kairo Flame Ronin, Tetsu Iron Vanguard, Rin Storm Blade,
-- Kuro Shadow Assassin, Sora Astral Champion, Arashi Wind Samurai):
--   * adds the `class_title` column used across the app,
--   * rewrites names/descriptions/art paths,
--   * renames the 5 evolution forms per hero (unlock levels kept),
--   * deactivates the retired cute characters (Momo, Mizu, Yuki, Hana),
--   * defensively un-equips any character that got deactivated.

ALTER TABLE characters ADD COLUMN IF NOT EXISTS class_title text;

UPDATE characters AS c
SET class_title    = v.class_title,
    description    = v.description,
    image_url      = v.image_url,
    static_image_path = v.static_image_path,
    sprite_idle_path  = NULL,
    sprite_walk_path  = NULL,
    sprite_victory_path = NULL,
    sprite_level_up_path = NULL
FROM (VALUES
  ('Kairo', 'Flame Ronin',
   'A ronin whose katana burns with unquenchable flame, forged by a thousand finished sessions.',
   'characters/kairo/preview.png', 'characters/kairo/preview.png'),
  ('Tetsu', 'Iron Vanguard',
   'A titan of iron and resolve whose great shield stops every distraction cold.',
   'characters/tetsu/preview.png', 'characters/tetsu/preview.png'),
  ('Rin', 'Storm Blade',
   'A duelist who moves like lightning and cuts procrastination down in a single stroke.',
   'characters/rin/preview.png', 'characters/rin/preview.png'),
  ('Kuro', 'Shadow Assassin',
   'A silent assassin of the night who hunts down every excuse before it can strike.',
   'characters/kuro/preview.png', 'characters/kuro/preview.png'),
  ('Sora', 'Astral Champion',
   'A champion sworn to the stars, channeling cosmic power into unbroken focus.',
   'characters/sora/preview.png', 'characters/sora/preview.png'),
  ('Arashi', 'Wind Samurai',
   'A samurai of the gale, faster than doubt and sharper than the wind itself.',
   'characters/arashi/preview.png', 'characters/arashi/preview.png')
) AS v(name, class_title, description, image_url, static_image_path)
WHERE c.name = v.name;

UPDATE character_forms AS f
SET form_name = v.form_name,
    image_url = v.image_url
FROM (VALUES
  ('Kairo', 1, 'Ember Initiate'),
  ('Kairo', 2, 'Blazing Samurai'),
  ('Kairo', 3, 'Flame Ronin'),
  ('Kairo', 4, 'Inferno Daimyo'),
  ('Kairo', 5, 'Kami of the Crimson Flame'),
  ('Tetsu', 1, 'Iron Squire'),
  ('Tetsu', 2, 'Steel Guardian'),
  ('Tetsu', 3, 'Iron Vanguard'),
  ('Tetsu', 4, 'Obsidian Bulwark'),
  ('Tetsu', 5, 'Kami of the Mountain'),
  ('Rin', 1, 'Storm Apprentice'),
  ('Rin', 2, 'Gale Swordsman'),
  ('Rin', 3, 'Storm Blade'),
  ('Rin', 4, 'Tempest Master'),
  ('Rin', 5, 'Kami of the Thunder'),
  ('Kuro', 1, 'Shadow Initiate'),
  ('Kuro', 2, 'Night Stalker'),
  ('Kuro', 3, 'Shadow Assassin'),
  ('Kuro', 4, 'Void Reaper'),
  ('Kuro', 5, 'Kami of the Dark'),
  ('Sora', 1, 'Star Novice'),
  ('Sora', 2, 'Starborn Knight'),
  ('Sora', 3, 'Astral Champion'),
  ('Sora', 4, 'Nova Warden'),
  ('Sora', 5, 'Kami of the Firmament'),
  ('Arashi', 1, 'Wind Trainee'),
  ('Arashi', 2, 'Gale Warrior'),
  ('Arashi', 3, 'Wind Samurai'),
  ('Arashi', 4, 'Sky Sovereign'),
  ('Arashi', 5, 'Kami of the Storm')
) AS v(ch_name, form_order, form_name)
JOIN characters AS c ON c.name = v.ch_name
WHERE f.character_id = c.id AND f.form_order = v.form_order;

UPDATE character_forms AS f
SET image_url = 'characters/' || c.name || '/preview.png'
FROM characters AS c
WHERE f.character_id = c.id
  AND c.name IN ('Kairo', 'Tetsu', 'Rin', 'Kuro', 'Sora', 'Arashi');

UPDATE characters SET active = false
WHERE name IN ('Momo', 'Mizu', 'Yuki', 'Hana');

-- Defensive: no user may stay equipped to a deactivated character.
DO $$
BEGIN
  UPDATE user_characters uc
  SET is_selected = false
  WHERE uc.is_selected
    AND uc.character_id IN (SELECT id FROM characters WHERE active = false);

  UPDATE user_characters uc
  SET is_selected = true
  FROM characters c
  WHERE c.id = uc.character_id AND c.name = 'Kairo'
    AND uc.user_id IN (
      SELECT user_id FROM user_characters
      WHERE is_selected = false
        AND character_id IN (SELECT id FROM characters WHERE name = 'Kairo')
    )
    AND NOT EXISTS (
      SELECT 1 FROM user_characters u2
      WHERE u2.user_id = uc.user_id AND u2.is_selected
    );
END $$;

-- Tell PostgREST to expose the new column.
DO $$ BEGIN
  PERFORM pg_notify('pgrst', 'reload schema');
END $$;
