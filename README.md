FocusSaga XP



FocusSaga XP is a gamified study timer app built around one simple loop:

Set a focus timer, study deeply, earn XP, level up original characters, collect coins, unlock rewards, and compete in daily rankings.

The goal is to make studying feel rewarding without turning the app into a complex game. The first version is planned as a free MVP built with Flutter and Supabase.

Project Status

Area

Status

Product plan

Ready

Brand name

FocusSaga XP

Logo concept

Drafted

Tech stack

Selected

Database architecture

Planned

Flutter implementation

Pending

Supabase setup

In progress

MVP release

Not launched

Table of Contents

Product Vision

Why This App

Core Features

User Flow

Core Game Loop

System Architecture

Tech Stack

Authentication Architecture

Timer Architecture

XP, Level, and Coin Economy

Character System

Store System

Daily Challenges

Leaderboard and Ranking

Database Architecture

Supabase Tables

Flutter Architecture

Folder Structure

Setup Requirements

MVP Roadmap

Future Scope

Legal and Content Rules

Build in Public

Product Vision

FocusSaga XP is designed for students and self-learners who want studying to feel like measurable progress.

Instead of only showing a timer, the app gives users:

XP for real focused minutes

Character progression

Level-up rewards

Coins after level clears

Unlockable backgrounds and timer skins

Daily challenges

Ranking and profile growth

The app should feel easy enough for a beginner to use in seconds, but rewarding enough that users want to return daily.

Why This App

Many study timer apps are either too plain or too complex. Some use passive mechanics like growing trees, but the user does not always feel strong progress after each session.

FocusSaga XP uses a more direct reward loop:

Study Time -> XP -> Character Level -> Coins -> Store Unlocks -> More Motivation

The product principle is:

Every completed study session should create visible progress.

Core Features

MVP Features

Google login

Terms and Privacy acceptance

Tutorial/onboarding screens

Countdown focus timer

Preset timers: 25 min, 50 min, 2 hours

Custom timer up to 3 hours

Pause, resume, and finish early

Session history

XP based on actual focused time

Character level system

50 starting coins

20 coins on every character level clear

Store for characters, backgrounds, timer skins, and reward animations

Daily challenges

Daily and weekly ranking

Profile screen

Later Features

Friends leaderboard

Class/group leaderboard

Seasonal events

Streak freeze

Push notifications

Parent/teacher reward mode

Premium cosmetics

Admin dashboard

User Flow

flowchart TD
    A[Open App] --> B[Splash Screen]
    B --> C{User Logged In?}
    C -- No --> D[Google Login]
    C -- Yes --> E[Load Profile]
    D --> E
    E --> F{Terms Accepted?}
    F -- No --> G[Accept Terms and Privacy]
    F -- Yes --> H{Tutorial Completed?}
    G --> H
    H -- No --> I[Tutorial Screens]
    H -- Yes --> J[Main App]
    I --> J
    J --> K[Focus Timer]
    J --> L[Characters]
    J --> M[Store]
    J --> N[Challenges]
    J --> O[Ranking]
    J --> P[Profile]

Core Game Loop

flowchart LR
    A[Choose Timer] --> B[Start Focus Session]
    B --> C[Study Until Timer Ends]
    C --> D{Completed Full Timer?}
    D -- Yes --> E[Earn XP + Completion Bonus]
    D -- No --> F[Earn XP for Actual Time]
    E --> G[Selected Character Gains XP]
    F --> G
    G --> H{Character Level Up?}
    H -- Yes --> I[Earn 20 Coins Per Level]
    H -- No --> J[XP Bar Moves Forward]
    I --> K[Unlock Store Items]
    J --> K
    K --> L[Update Daily Challenges]
    L --> M[Update Rank Points]
    M --> N[Show Reward Summary]

System Architecture

flowchart TB
    subgraph Client["Flutter Mobile App"]
        UI[Flutter UI]
        State[Riverpod State Management]
        Router[go_router Navigation]
        Services[Service Layer]
        Cache[Local Cache]
    end

    subgraph Backend["Supabase Backend"]
        Auth[Supabase Auth]
        DB[(Postgres Database)]
        Storage[Supabase Storage]
        RLS[Row Level Security]
    end

    subgraph External["External Services"]
        Google[Google OAuth]
        GitHub[GitHub Repository]
        Legal[Next.js / Static Legal Pages]
    end

    UI --> State
    State --> Router
    State --> Services
    Services --> Auth
    Services --> DB
    Services --> Storage
    Services --> Cache
    Auth --> Google
    DB --> RLS
    GitHub --> UI
    Legal --> UI

Tech Stack

Layer

Technology

Mobile app

Flutter

Language

Dart

State management

Riverpod

Navigation

go_router

Authentication

Supabase Auth

Social login

Google OAuth

Database

Supabase Postgres

Storage

Supabase Storage

Legal pages

Next.js / GitHub Pages / Vercel

Version control

GitHub

Authentication Architecture

Package name:

com.startupzilla.focussagaxp

Google OAuth is used through Supabase Auth.

sequenceDiagram
    participant User
    participant App as Flutter App
    participant Supabase as Supabase Auth
    participant Google as Google OAuth
    participant DB as Supabase DB

    User->>App: Tap Continue with Google
    App->>Supabase: Start Google OAuth
    Supabase->>Google: Redirect user
    Google->>Supabase: Return auth callback
    Supabase->>App: Return session
    App->>DB: Check profiles table
    alt New user
        App->>DB: Create profile with 50 coins
    else Returning user
        App->>DB: Load profile
    end
    App->>DB: Check terms and tutorial state
    App->>User: Navigate to correct screen

New user defaults:

Field

Value

coins

50

profile_level

1

tutorial_completed

false

terms accepted

false

selected character

starter character

selected background

starter background

selected timer skin

starter timer skin

Timer Architecture

The timer must reward only real focused time.

stateDiagram-v2
    [*] --> Idle
    Idle --> Running: Start
    Running --> Paused: Pause
    Paused --> Running: Resume
    Running --> Completed: Countdown reaches zero
    Running --> FinishedEarly: User taps finish
    Paused --> FinishedEarly: User taps finish
    Completed --> SaveSession
    FinishedEarly --> SaveSession
    SaveSession --> RewardCalculation
    RewardCalculation --> RewardSummary
    RewardSummary --> Idle

Session data saved:

planned minutes

actual minutes

start time

end time

completion status

pause count

XP earned

coins earned

rank points

Rules:

Full timer completion gives bonus XP.

Early finish gives XP only for actual focused minutes.

Maximum single session for MVP: 3 hours.

Background/resume should be handled with timestamps, not only in-memory seconds.

XP, Level, and Coin Economy

Core Rules

1 focused minute = 1 XP

Full timer completion = 20% XP bonus

Each character has 50 levels

Each level clear = 20 coins

New users start with 50 coins

Coins unlock cosmetics and rewards

Coins do not increase leaderboard rank directly

XP Formula

base_xp = actual_focused_minutes

if completed_full_timer:
  final_xp = round(base_xp * 1.2)
else:
  final_xp = base_xp

Example Rewards

Session

Actual Time

Completed

XP

Short focus

25 min

Yes

30 XP

Pomodoro pair

50 min

Yes

60 XP

Deep session

120 min

Yes

144 XP

Early finish

18 min

No

18 XP

Level Reward

coins_earned = levels_cleared * 20

Character System

Characters are original anime-inspired study companions. They are not copied from existing anime, superhero, game, movie, or cartoon IP.

Each character has:

Name

Rarity

Price

Description

50 levels

5 evolution forms

Idle animation

Victory animation

Locked/unlocked state

Evolution Flow

flowchart LR
    A[Level 1: Base Form] --> B[Level 10: Form 2]
    B --> C[Level 20: Form 3]
    C --> D[Level 35: Form 4]
    D --> E[Level 50: Max Form]

Example Original Characters

Character

Rarity

Theme

Rookie Scholar

Common

Starter study hero

Shadow Ninja Student

Rare

Silent discipline

Flame Sword Learner

Rare

High-energy focus

Galaxy Scholar

Epic

Space progress

Cyber Monk

Epic

Calm deep work

Storm Runner

Epic

Speed and streaks

Crystal Mage

Rare

Memory and revision

Dragon Exam Master

Legendary

Exam preparation

Neon Samurai

Legendary

Night focus

Star Captain

Legendary

Long-term goals

Store System

Users spend coins in the store.

Store categories:

Characters

Backgrounds

Timer skins

Reward animations

flowchart TD
    A[Open Store] --> B[Choose Category]
    B --> C[Select Item]
    C --> D{Already Owned?}
    D -- Yes --> E[Equip Item]
    D -- No --> F{Enough Coins?}
    F -- No --> G[Show Not Enough Coins]
    F -- Yes --> H[Buy Item]
    H --> I[Deduct Coins]
    I --> J[Add to Inventory]
    J --> K[Record Purchase]
    K --> E

Example Store Pricing

Item

Category

Price

Rookie Scholar

Character

Free

Shadow Ninja Student

Character

100

Galaxy Scholar

Character

350

Cozy Desk

Background

Free

Rainy Window

Background

80

Neon Room

Background

150

Forest Focus

Background

220

Classic Circle

Timer Skin

Free

Fire Ring

Timer Skin

100

Galaxy Timer

Timer Skin

180

Reward Burst

Animation

120

Daily Challenges

Daily challenges are used to improve retention and give users small goals.

Examples:

Study 25 minutes today.

Complete 2 focus sessions.

Study 120 minutes today.

Complete one session without pause.

Level up any character.

Use a new background.

flowchart TD
    A[New Day Starts] --> B[Assign Daily Challenge Set]
    B --> C[User Studies or Uses App]
    C --> D[Update Challenge Progress]
    D --> E{Challenge Complete?}
    E -- No --> C
    E -- Yes --> F[Enable Claim Button]
    F --> G[Claim Reward]
    G --> H[Add XP, Coins, or Rank Points]

Leaderboard and Ranking

MVP ranking:

Daily ranking

Weekly ranking

Future ranking:

Friends ranking

Class/group ranking

Global seasonal ranking

Ranking must be based on real study activity, not paid advantage.

rank_points = focused_minutes + challenge_bonus + streak_bonus

flowchart LR
    A[Study Sessions] --> D[Rank Points]
    B[Daily Challenges] --> D
    C[Streak Bonus] --> D
    D --> E[Daily Leaderboard]
    D --> F[Weekly Leaderboard]

Database Architecture

erDiagram
    auth_users ||--|| profiles : owns
    profiles ||--o{ terms_acceptance : accepts
    profiles ||--o{ user_characters : owns
    profiles ||--o{ user_inventory : owns
    profiles ||--o{ study_sessions : creates
    profiles ||--o{ user_daily_challenges : tracks
    profiles ||--o{ store_purchases : makes

    characters ||--o{ character_forms : has
    characters ||--o{ user_characters : unlocked_by
    characters ||--o{ study_sessions : used_in

    backgrounds ||--o{ user_inventory : unlocked_by
    timer_skins ||--o{ user_inventory : unlocked_by
    reward_animations ||--o{ user_inventory : unlocked_by

    daily_challenges ||--o{ user_daily_challenges : assigned_to

    profiles {
        uuid user_id PK
        text display_name
        text email
        text avatar_url
        int coins
        int profile_level
        boolean tutorial_completed
        uuid selected_character_id
        uuid selected_background_id
        uuid selected_timer_skin_id
        timestamptz created_at
        timestamptz updated_at
    }

    characters {
        uuid id PK
        text name
        text rarity
        int price
        text description
        text image_path
        boolean is_active
    }

    user_characters {
        uuid id PK
        uuid user_id FK
        uuid character_id FK
        int level
        int xp
        boolean equipped
    }

    study_sessions {
        uuid id PK
        uuid user_id FK
        uuid character_id FK
        int planned_minutes
        int actual_minutes
        boolean completed
        int paused_count
        int xp_earned
        int coins_earned
        int rank_points
        timestamptz started_at
        timestamptz ended_at
    }

Supabase Tables

User Data

Table

Purpose

profiles

User profile, coins, level, selected items

terms_acceptance

Terms/privacy version acceptance

user_characters

User-owned characters and XP

user_inventory

Owned backgrounds, timer skins, animations

study_sessions

Saved focus sessions

user_daily_challenges

Daily challenge progress

store_purchases

Purchase history

Master Data

Table

Purpose

characters

Character catalog

character_forms

Evolution forms per character

backgrounds

Background catalog

timer_skins

Timer skin catalog

reward_animations

Reward animation catalog

daily_challenges

Challenge templates

Security Model

Use Supabase Row Level Security:

Users can read/update only their own profile.

Users can read public master data.

Users can write only their own sessions, inventory, and challenge progress.

Users cannot edit master store items.

Leaderboards can expose safe public ranking data only.

Flutter Architecture

flowchart TB
    A[main.dart] --> B[App Root]
    B --> C[Router]
    B --> D[Theme]
    C --> E[Feature Screens]
    E --> F[Riverpod Providers]
    F --> G[Services]
    G --> H[Supabase Client]
    H --> I[(Database/Auth/Storage)]

Recommended packages:

supabase_flutter

flutter_riverpod

go_router

shared_preferences

intl

cached_network_image

lottie

Folder Structure

lib/
  main.dart
  app/
    app.dart
    router.dart
    theme.dart
  core/
    constants/
    errors/
    utils/
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
      screens/
      widgets/
      providers/
    onboarding/
      screens/
      widgets/
      providers/
    terms/
      screens/
      providers/
    focus/
      screens/
      widgets/
      providers/
      models/
    characters/
      screens/
      widgets/
      providers/
      models/
    store/
      screens/
      widgets/
      providers/
      models/
    challenges/
      screens/
      widgets/
      providers/
      models/
    ranking/
      screens/
      widgets/
      providers/
      models/
    profile/
      screens/
      widgets/
      providers/
  shared/
    widgets/
    models/
    styles/

Setup Requirements

Accounts

GitHub

Supabase

Google Cloud Console

Optional: Vercel, Render, or GitHub Pages for legal pages

Local Tools

Flutter SDK

Android Studio

VS Code

Git

Android emulator or real Android device

Java keytool through Android Studio JDK

Google Auth Setup

Supabase Google Provider needs:

Web OAuth Client ID

Web OAuth Client Secret

Android OAuth Client ID

Supabase callback URL registered in Google Cloud

Google OAuth Client IDs look like:

1234567890-example.apps.googleusercontent.com

Do not use the app name as a client ID.

MVP Roadmap

gantt
    title FocusSaga XP MVP Roadmap
    dateFormat  YYYY-MM-DD
    section Foundation
    Flutter Project Setup      :a1, 2026-08-11, 2d
    Supabase Setup             :a2, after a1, 2d
    Google Auth                :a3, after a2, 3d
    Terms and Tutorial         :a4, after a3, 2d
    section Core Loop
    Focus Timer                :b1, after a4, 3d
    Session Saving             :b2, after b1, 2d
    XP Coins Levels            :b3, after b2, 3d
    Character System           :b4, after b3, 4d
    Store System               :b5, after b4, 4d
    section Retention
    Daily Challenges           :c1, after b5, 3d
    Ranking                    :c2, after c1, 3d
    Profile and Polish         :c3, after c2, 3d

Build Milestones

Flutter project setup

Theme and routing

Supabase connection

Google login

Profile creation

Terms and privacy screen

Tutorial screens

Main app shell

Focus timer UI

Timer logic

Session saving

XP, coins, and level system

Character system

Store system

Daily challenges

Ranking

Profile

Testing and release prep

Future Scope

After the MVP is validated:

Real-time friend rankings

Class/group competitions

Seasonal character drops

Streak freeze

Push reminders

Parent reward dashboard

Coaching institute dashboard

Premium cosmetic packs

Analytics dashboard

Admin content panel

Legal and Content Rules

FocusSaga XP should use only original characters and assets.

Do not use:

Real anime characters

Real anime transformation names

Marvel/DC characters

Movie/game/cartoon characters

Protected logos

Copied costume designs

Copied names or phrases

Safe direction:

Original anime-inspired characters

Original evolution forms

Original names

Original visual designs

Original animations

Build in Public

Suggested repo name:

focussaga-xp

Suggested repo description:

A gamified study timer app where users earn XP, level up characters, unlock rewards, and build focus habits.

Suggested LinkedIn intro:

I am building FocusSaga XP, a gamified study timer app where users complete focus sessions, earn XP, level up original characters, unlock rewards, and compete in daily challenges.

The goal is simple: make studying feel rewarding without making the app complex.
