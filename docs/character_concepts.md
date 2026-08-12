# Original Characters — Design Concepts & Art

All characters in **FocusSaga XP** are original creations. No copyrighted
characters (anime, games, movies, comics) appear anywhere. Each hero has a
distinct silhouette, palette and class so the app stays recognizable without
infringing on any IP.

The app ships with **six original adult dark-fantasy warriors** (the chibi
animal mascot roster was retired in migration `m28`). Their preview art is
procedurally generated (`tool/generate_warrior_art.dart`) and rendered with a
light idle animation (`lib/shared/widgets/character_idle_widget.dart`). The
PNGs are placeholders: replace them with real hand-drawn/AI art later by
writing to the **same paths** — no code changes are needed.

---

## 1. Art format (must never change)

| Field | Value |
|---|---|
| File | `assets/characters/<slug>/preview.png` |
| Size | 384 × 384 px, transparent background |
| Style | full-body hero, straight-on, dark-fantasy anime (no gore, no sexual content) |
| Rendering | `CharacterIdleWidget` — gentle float bob, breathing scale, pulsing theme-colored glow |

Asset layout (mirrors DB `static_image_path` from migration `m28`):

```
assets/characters/<slug>/preview.png
```

Art lookups are by display name via `CharacterIdleSpec.forName(...)` in
`lib/shared/widgets/character_idle_widget.dart`. Missing art falls back to a
deterministic warrior silhouette — never a spinner.

---

## 2. The six warriors

### KAIRO — the Flame Ronin ・ starter hero
- **Theme**: a wandering ronin whose katana burns with unquenchable flame,
  forged by a thousand finished sessions.
- **Palette**: ember orange `#FF5A2A`, dark iron armor, gold blade glow.
- **Silhouette**: kabuto helmet with flame-hued crest, flowing cloak, one
  katana.
- **Idle**: embers drifting, flame pulse on the blade, cloak sway.
- **Evolution**: Ember Initiate (Lv 1) → Blazing Samurai (Lv 3) → Flame Ronin
  (Lv 6) → Inferno Daimyo (Lv 9) → Kami of the Crimson Flame (Lv 12).

### TETSU — the Iron Vanguard ・ 500 coins / Lv 5
- **Theme**: a titan of iron and resolve whose great shield stops every
  distraction cold.
- **Palette**: steel blue `#4E8FE6`, brushed metal armor, white-hot core.
- **Silhouette**: full steel helm, massive pauldrons, tower shield.
- **Idle**: shield gleam pulse, armor plate glint.
- **Evolution**: Iron Squire (Lv 1) → Steel Guardian (Lv 5) → Iron Vanguard
  (Lv 9) → Obsidian Bulwark (Lv 13) → Kami of the Mountain (Lv 17).

### RIN — the Storm Blade ・ 600 coins / Lv 6
- **Theme**: a duelist who moves like lightning and cuts procrastination down
  in a single stroke.
- **Palette**: storm gold `#F2C94C`, light leather armor, crackling edge.
- **Silhouette**: twin blades, wind-torn scarf, narrow storm-eyed visor.
- **Idle**: lightning arcs between the blades, scarf billows.
- **Evolution**: Storm Apprentice (Lv 1) → Gale Swordsman (Lv 8) → Storm Blade
  (Lv 12) → Tempest Master (Lv 16) → Kami of the Thunder (Lv 20).

### KURO — the Shadow Assassin ・ 700 coins / Lv 7
- **Theme**: a silent assassin of the night who hunts down every excuse before
  it can strike.
- **Palette**: violet-shadow `#8A7FD4`, black hooded cloak, amber eyes.
- **Silhouette**: deep hood, twin short blades, coiled smoke.
- **Idle**: smoke wisps, blade glint in the dark.
- **Evolution**: Shadow Initiate (Lv 1) → Night Stalker (Lv 7) → Shadow
  Assassin (Lv 11) → Void Reaper (Lv 15) → Kami of the Dark (Lv 19).

### SORA — the Astral Champion ・ 1000 coins / Lv 10
- **Theme**: a champion sworn to the stars, channeling cosmic power into
  unbroken focus.
- **Palette**: celestial gold `#C9A86A`, white-gold star armor, nebula cloak.
- **Silhouette**: crowned helm, star-blade, star-speckled cape.
- **Idle**: drifting star motes, blade starlight shimmer.
- **Evolution**: Star Novice (Lv 1) → Starborn Knight (Lv 12) → Astral
  Champion (Lv 18) → Nova Warden (Lv 24) → Kami of the Firmament (Lv 30).

### ARASHI — the Wind Samurai ・ 1200 coins / Lv 12
- **Theme**: a samurai of the gale, faster than doubt and sharper than the
  wind itself.
- **Palette**: gale teal `#4FD1B8`, light scale armor, glowing wind katana.
- **Silhouette**: sweeping helmet crest, wind-torn sleeves, curved katana.
- **Idle**: swirling wind trails, blade wind pulse.
- **Evolution**: Wind Trainee (Lv 1) → Gale Warrior (Lv 12) → Wind Samurai
  (Lv 17) → Sky Sovereign (Lv 22) → Kami of the Storm (Lv 27).

---

## 3. AI prompts for real hero art

The generated art is a **placeholder**. When commissioning real art, use this
prompt shape (works in Midjourney / DALL·E / Stable Diffusion / Firefly). The
output must be a single **384 × 384 transparent full-body hero** on the same
path so existing code keeps working.

**Master prompt template (fill in the parts in `[...]`):**

```
Game character portrait, single transparent PNG, 384x384 px, no background,
no text, full body, straight-on view, centered, dark-fantasy anime style,
adult muscular warrior, serious expression, cel shading, clean lines.

Character: [KAIRO the flame ronin — adult male ronin in dark iron armor with
a kabuto helmet, one burning katana, ember-orange cloak, embers drifting
around him].

Palette: [ember orange #FF5A2A, dark iron #2A2D35, gold #FFB347].
Lighting: dramatic rim light from the weapon, subtle glow under the feet.
```

**Per-hero flavor lines to append (pick the matching one):**

- Kairo: `flame ronin; kabuto helmet with flame crest; burning katana;
  ember-orange cloak; drifting embers`.
- Tetsu: `iron vanguard; full steel helm; massive pauldrons; tower shield;
  brushed metal armor; white-hot core glow`.
- Rin: `storm blade duelist; twin blades; wind-torn scarf; narrow storm-eyed
  visor; crackling lightning arcs`.
- Kuro: `shadow assassin; deep hood; twin short blades; violet-black cloak;
  amber eyes; wisps of smoke`.
- Sora: `astral champion; crowned helm; star-blade; white-gold star armor;
  star-speckled nebula cape`.
- Arashi: `wind samurai; sweeping helmet crest; curved wind katana; teal
  scale armor; swirling wind trails`.

Drop the finished PNG into `assets/characters/<slug>/preview.png` and the app
does the rest (idle animation and all screens pick it up automatically).

---

## 4. Adding a new character later

1. **DB**: insert into `characters` (+ its 5 `character_forms`) with
   `class_title`, and `static_image_path = 'characters/<slug>/preview.png'`.
2. **Art**: write the preview PNG into `assets/characters/<slug>/preview.png`
   — 384 × 384, transparent background, same style as section 1.
3. **Config**: add a `CharacterIdleSpec` entry to `CharacterIdleSpec.all` in
   `lib/shared/widgets/character_idle_widget.dart` (id = slug, name = display
   name, class title, accent color).
4. Nothing else — the widget, fallbacks and all screens pick it up
   automatically. Heroes without art render the warrior silhouette until art
   exists.
