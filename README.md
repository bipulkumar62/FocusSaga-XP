# FocusSaga XP

<p align="center">
  <img src="assets/brand/focussaga-wordmark.png" alt="FocusSaga XP Logo" width="420"/>
</p>

<p align="center">
  <b>Gamified study timer app where users focus, earn XP, level up characters, unlock seasons, and climb rankings.</b>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-Mobile-blue?style=for-the-badge&logo=flutter"/>
  <img src="https://img.shields.io/badge/Supabase-Backend-green?style=for-the-badge&logo=supabase"/>
  <img src="https://img.shields.io/badge/Dart-Language-blue?style=for-the-badge&logo=dart"/>
  <img src="https://img.shields.io/badge/Status-MVP%20Build-orange?style=for-the-badge"/>
</p>

---

## Overview

**FocusSaga XP** is a Flutter-based gamified study timer app.

The app helps users stay consistent by turning focused study sessions into a game-like progression system. Users set a timer, study, earn XP, level up characters, receive coins, unlock beautiful animated seasons/backgrounds, complete daily challenges, and compete on leaderboards.

The goal is simple:

> Make studying feel rewarding without making the app complicated.

---

## Screenshots

> Add your real screenshots inside `assets/screenshots/`.

<p align="center">
  <img src="assets/screenshots/focus.png" width="220" alt="Focus Screen"/>
  <img src="assets/screenshots/characters.png" width="220" alt="Characters Screen"/>
  <img src="assets/screenshots/store.png" width="220" alt="Store Screen"/>
</p>

<p align="center">
  <img src="assets/screenshots/challenges.png" width="220" alt="Challenges Screen"/>
  <img src="assets/screenshots/ranking.png" width="220" alt="Ranking Screen"/>
  <img src="assets/screenshots/profile.png" width="220" alt="Profile Screen"/>
</p>

---

## Core Features

- Anonymous Supabase auth for frictionless start
- Optional profile name setup
- Terms and Privacy acceptance flow
- Tutorial/onboarding flow
- Focus countdown timer
- Timer presets: `25 min`, `50 min`, `2 hours`, custom timer
- Pause, resume, and finish early
- XP based on actual focused minutes
- Character leveling system
- 50 starting coins
- 20 coins per level clear
- Unlockable characters
- Unlockable animated seasons/backgrounds
- Unlockable timer skins
- Unlockable reward animations
- Daily challenges
- Daily and weekly leaderboard
- Profile stats
- Soft UI / Clean Pastel Minimal UI
- Transparent/semi-transparent panels over animated backgrounds

---

## Core App Flow

```mermaid
flowchart TD
    A[Open App] --> B[Splash Screen]
    B --> C{Supabase Session Exists?}
    C -- No --> D[Anonymous Sign In]
    C -- Yes --> E[Load Profile]
    D --> E
    E --> F{Profile Exists?}
    F -- No --> G[Create Profile + 50 Coins]
    F -- Yes --> H[Load Starter Items]
    G --> H
    H --> I{Terms Accepted?}
    I -- No --> J[Terms and Privacy Screen]
    I -- Yes --> K{Tutorial Completed?}
    J --> K
    K -- No --> L[Tutorial Screens]
    K -- Yes --> M{Name Set?}
    L --> M
    M -- No --> N[Enter Display Name]
    M -- Yes --> O[Main App]
    N --> O
```

---

## Main Navigation

```mermaid
flowchart LR
    A[Main App] --> B[Focus]
    A --> C[Characters]
    A --> D[Store]
    A --> E[Challenges]
    A --> F[Ranking]
    A --> G[Profile]
```

---

## Game Loop

```mermaid
flowchart LR
    A[Set Timer] --> B[Study Session]
    B --> C{Timer Completed?}
    C -- Yes --> D[XP + 20% Bonus]
    C -- No --> E[XP for Actual Time]
    D --> F[Character Gains XP]
    E --> F
    F --> G{Level Up?}
    G -- Yes --> H[+20 Coins]
    G -- No --> I[XP Bar Progress]
    H --> J[Unlock Store Items]
    I --> J
    J --> K[Season / Character / Skin]
    K --> L[Daily Challenge Progress]
    L --> M[Leaderboard Points]
```

---

## Tech Stack

| Layer | Technology |
|---|---|
| Mobile App | Flutter |
| Language | Dart |
| Backend | Supabase |
| Auth | Supabase Anonymous Auth |
| Database | Supabase Postgres |
| Storage | Supabase Storage |
| State Management | Riverpod |
| Routing | go_router |
| Images | Local assets + Supabase Storage |
| Animation | Flutter CustomPainter / Animated Widgets |
| Future Animation | Flame / Rive |
| Version Control | GitHub |

---

## System Architecture

```mermaid
flowchart TB
    subgraph Client["Flutter App"]
        UI[UI Screens]
        Router[go_router]
        State[Riverpod Providers]
        Services[Repository / Service Layer]
        Cache[Local Cache]
        Animations[Animated Background + Characters]
    end

    subgraph Supabase["Supabase Backend"]
        Auth[Anonymous Auth]
        DB[(Postgres Database)]
        Storage[Storage Buckets]
        RLS[Row Level Security]
        RPC[RPC Functions]
    end

    UI --> Router
    UI --> State
    State --> Services
    Services --> Cache
    Services --> Auth
    Services --> DB
    Services --> Storage
    DB --> RLS
    Services --> RPC
    UI --> Animations
```

---

## Timer State Machine

```mermaid
stateDiagram-v2
    [*] --> Idle
    Idle --> Running: Start
    Running --> Paused: Pause
    Paused --> Running: Resume
    Running --> Completed: Timer reaches zero
    Running --> FinishedEarly: Finish early
    Paused --> FinishedEarly: Finish early
    Completed --> SaveSession
    FinishedEarly --> SaveSession
    SaveSession --> CalculateRewards
    CalculateRewards --> UpdateXP
    UpdateXP --> UpdateCoins
    UpdateCoins --> UpdateChallenges
    UpdateChallenges --> UpdateLeaderboard
    UpdateLeaderboard --> RewardSummary
    RewardSummary --> Idle
```

---

## XP and Coin System

| Rule | Value |
|---|---|
| Focused time | `1 XP / minute` |
| Full completion bonus | `+20% XP` |
| XP per level | `100 XP` |
| Level reward | `20 coins` |
| Starting coins | `50 coins` |
| Max session length | `3 hours` |
| Level cap | `50` |

### XP Formula

```text
base_xp = actual_focused_minutes

if completed == true:
    final_xp = round(base_xp * 1.2)
else:
    final_xp = base_xp
```

### Example

| Session | Actual Time | Completed | XP |
|---|---:|---|---:|
| Quick Focus | 25 min | Yes | 30 XP |
| Deep Work | 120 min | Yes | 144 XP |
| Early Finish | 18 min | No | 18 XP |

---

## Reward Distribution

```mermaid
pie title Reward Sources
    "Study XP" : 50
    "Level Coins" : 25
    "Daily Challenges" : 15
    "Streak Bonus" : 10
```

---

## Characters

Characters are original mature fantasy/anime-inspired warriors.  
No copyrighted anime, Marvel, DC, game, movie, or cartoon characters are used.

### Character Types

| Character | Theme | Style |
|---|---|---|
| Kairo | Flame Ronin | Muscular fire swordsman |
| Tetsu | Iron Vanguard | Heavy armored warrior |
| Rin | Storm Blade | Lightning dual-blade fighter |
| Kuro | Shadow Assassin | Dark sword assassin |
| Sora | Astral Champion | Cosmic sword warrior |
| Arashi | Wind Samurai | Wind katana warrior |

### Character Evolution

```mermaid
flowchart LR
    A[Level 1: Base Form] --> B[Level 10: Form 2]
    B --> C[Level 20: Form 3]
    C --> D[Level 35: Form 4]
    D --> E[Level 50: Max Form]
```

---

## Animated Seasons

FocusSaga XP uses unlockable global animated seasons.  
Each season changes the full app background and creates a different mood.

### Season Unlocks

| Season | Status | Visual |
|---|---|---|
| Forest Morning | Free / Default | Trees, blurred mountains, falling leaves |
| Rainy Window | Locked | Rain drops and soft blue mood |
| Snow Pine | Locked | Snow, pine trees, distant mountains |
| Sunset Garden | Locked | Warm sunset, petals, garden silhouettes |
| Neon Night | Locked | Dark neon particles |
| Cherry Blossom | Locked | Pink petals and soft spring background |
| Celestial Aurora | Final Legendary | Aurora sky, cosmic particles, premium final unlock |

### Season Unlock Flow

```mermaid
flowchart TD
    A[Open Store] --> B[Go to Seasons]
    B --> C[Select Season]
    C --> D{Owned?}
    D -- Yes --> E[Equip Season]
    D -- No --> F{Enough Coins?}
    F -- No --> G[Show Locked / Need Coins]
    F -- Yes --> H[Buy Season]
    H --> I[Deduct Coins]
    I --> J[Add to Inventory]
    J --> E
    E --> K[Apply Globally to All Screens]
```

---

## Global Background System

```mermaid
flowchart TB
    A[Selected Season in Profile] --> B[Season Provider]
    B --> C[Global Background Wrapper]
    C --> D[Animated CustomPainter Layer]
    C --> E[Transparent Soft UI Layer]
    E --> F[Current Screen Content]
```

Background rules:

- One global background layer wraps all screens
- UI cards are semi-transparent
- Text remains readable
- Particles are lightweight
- Store previews stay static for performance
- Only equipped season animates globally

---

## Store System

Store categories:

- Characters
- Seasons
- Backgrounds
- Timer skins
- Reward animations

```mermaid
flowchart TD
    A[Store] --> B[Characters]
    A --> C[Seasons]
    A --> D[Timer Skins]
    A --> E[Reward Animations]
    B --> F[Buy or Equip]
    C --> F
    D --> F
    E --> F
    F --> G[Update Inventory]
    G --> H[Update Profile Selection]
```

---

## Daily Challenges

Example challenges:

- Study 25 minutes today
- Complete 2 sessions
- Study 120 minutes total
- Complete a session without pause
- Level up a character
- Unlock or equip a season

```mermaid
flowchart TD
    A[New Day] --> B[Assign Daily Challenges]
    B --> C[User Studies]
    C --> D[Update Challenge Progress]
    D --> E{Challenge Complete?}
    E -- No --> C
    E -- Yes --> F[Claim Reward]
    F --> G[Add XP / Coins / Rank Points]
```

---

## Leaderboard

Leaderboard rank is based on real study activity, not coins or purchases.

```text
rank_points = focused_minutes + challenge_bonus + streak_bonus
```

```mermaid
flowchart LR
    A[Study Sessions] --> D[Rank Points]
    B[Challenge Rewards] --> D
    C[Streak Bonus] --> D
    D --> E[Daily Ranking]
    D --> F[Weekly Ranking]
```

---

## Database Design

```mermaid
erDiagram
    users ||--|| profiles : owns
    profiles ||--o{ study_sessions : creates
    profiles ||--o{ user_characters : owns
    profiles ||--o{ user_inventory : owns
    profiles ||--o{ store_purchases : makes
    profiles ||--o{ user_daily_challenges : tracks

    characters ||--o{ character_forms : has
    characters ||--o{ user_characters : unlocked_by

    seasons ||--o{ user_inventory : unlocked_by
    timer_skins ||--o{ user_inventory : unlocked_by
    reward_animations ||--o{ user_inventory : unlocked_by

    daily_challenges ||--o{ user_daily_challenges : assigned_to
```

---

## Main Database Tables

| Table | Purpose |
|---|---|
| profiles | User profile, coins, level, selected season |
| terms_acceptance | Terms and privacy acceptance |
| characters | Character catalog |
| character_forms | Evolution forms |
| user_characters | User-owned characters and XP |
| seasons/backgrounds | Unlockable app backgrounds |
| timer_skins | Timer styles |
| reward_animations | Reward effects |
| user_inventory | Owned items |
| store_purchases | Purchase history |
| study_sessions | Focus session records |
| daily_challenges | Challenge templates |
| user_daily_challenges | User challenge progress |

---

## Flutter Folder Structure

```text
lib/
  main.dart
  app/
    app.dart
    router.dart
    theme.dart
    app_shell.dart
  core/
    constants/
    utils/
    errors/
  services/
    supabase_service.dart
    auth_service.dart
    profile_service.dart
    timer_service.dart
    store_service.dart
    challenge_service.dart
    ranking_service.dart
  features/
    auth/
    onboarding/
    terms/
    focus/
    characters/
    store/
    challenges/
    ranking/
    profile/
  shared/
    widgets/
      season_background_widget.dart
      soft_panel.dart
      character_idle_widget.dart
    models/
    styles/
```

---

## Asset Structure

```text
assets/
  brand/
    focussaga-wordmark.png
    focussaga-icon.png

  screenshots/
    focus.png
    characters.png
    store.png
    challenges.png
    ranking.png
    profile.png

  characters/
    kairo/
      preview.png
      form_1.png
      form_2.png
      form_3.png
      form_4.png
      form_5.png

  seasons/
    forest_morning/
      preview.png
    rainy_window/
      preview.png
    snow_pine/
      preview.png
    sunset_garden/
      preview.png
    neon_night/
      preview.png
    cherry_blossom/
      preview.png
    celestial_aurora/
      preview.png
```

---

## Performance Strategy

- Cache master data like characters, seasons, timer skins, and reward animations
- Do not call Supabase inside widget build methods
- Use Riverpod providers with loading/error/data states
- Use `RepaintBoundary` around animated backgrounds
- Keep particle count low
- Use pagination for leaderboard
- Use indexes on frequent query fields
- Avoid infinite loading screens
- Show retry buttons on errors

---

## Security Rules

- Users can read/write only their own profile data
- Users can read public master data
- Users cannot edit store catalog data
- Store purchases are atomic
- Duplicate purchases are blocked
- Coins cannot go negative
- Session rewards are guarded against double save
- Leaderboard does not use paid coins or purchases

---

## MVP Roadmap

```mermaid
gantt
    title FocusSaga XP MVP Roadmap
    dateFormat YYYY-MM-DD

    section Foundation
    Flutter Setup          :a1, 2026-08-12, 2d
    Supabase Setup         :a2, after a1, 2d
    Anonymous Auth         :a3, after a2, 2d
    Terms Tutorial         :a4, after a3, 2d

    section Core App
    Focus Timer            :b1, after a4, 3d
    XP Coins Levels        :b2, after b1, 3d
    Characters             :b3, after b2, 4d
    Store                  :b4, after b3, 4d

    section Visual System
    Seasons Backgrounds    :c1, after b4, 4d
    Soft UI Polish         :c2, after c1, 3d

    section Growth
    Challenges             :d1, after c2, 3d
    Ranking                :d2, after d1, 3d
    Release Prep           :d3, after d2, 3d
```

---

## Setup Requirements

Required tools:

- Flutter SDK
- Android Studio
- VS Code
- Git
- Supabase account
- GitHub account

Run project:

```bash
flutter pub get
flutter run
```

Run in Chrome:

```bash
flutter run -d chrome --web-port 50068
```

Build Android App Bundle:

```bash
flutter build appbundle --release
```

---

## Legal Rules

This app should use only original assets.

Do not use:

- Real anime characters
- Real anime transformation names
- Marvel or DC characters
- Movie/game/cartoon characters
- Protected logos
- Copied costume designs

---

## Future Scope

- Real Google login
- Friends leaderboard
- Class/group ranking
- Flame sprite animations
- Rive premium backgrounds
- Push notifications
- Streak freeze
- Parent/teacher reward dashboard
- Premium cosmetic packs
- Play Store release

---

## License

No license selected yet.

Before public release, decide whether the project should remain proprietary or use an open-source license such as MIT or Apache-2.0.
