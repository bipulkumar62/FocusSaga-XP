FocusSaga XP

FocusSaga XP is a gamified study timer app where users complete focused study sessions, earn XP, level up original anime-inspired characters, collect coins, unlock store items, complete daily challenges, and climb rankings.

The app is designed to make studying feel like visible progress in a game without making the interface complex.

Status: Planning and MVP architecture

Table of Contents

Overview

Core Idea

Main Features

App Flow

Game Loop

Architecture

Tech Stack

Authentication Flow

XP, Coins, and Levels

Characters and Evolutions

Store System

Daily Challenges

Ranking System

Database Design

Flutter Folder Structure

Setup Requirements

MVP Roadmap

Future Monetization

Legal and Content Rules

Build in Public

Overview

Most study timer apps only track time or grow a simple tree. FocusSaga XP adds a light RPG-style reward system:

Set a study timer.

Complete focused study.

Earn XP.

Level up a selected character.

Get coins after level clears.

Unlock characters, backgrounds, timer skins, and reward animations.

Complete daily challenges.

Compete in rankings.

The first version will be free and focused on validating whether users enjoy the loop enough to return daily.

Core Idea

flowchart LR
    A[Set Study Timer] --> B[Start Focus Session]
    B --> C[Timer Counts Down]
    C --> D{Session Complete?}
    D -- Yes --> E[Earn XP Bonus]
    D -- Finish Early --> F[Earn XP for Actual Time]
    E --> G[Character XP Increases]
    F --> G
    G --> H{Level Up?}
    H -- Yes --> I[Get 20 Coins]
    H -- No --> J[XP Bar Progress]
    I --> K[Unlock Store Items]
    J --> K
    K --> L[Daily Challenge Progress]
    L --> M[Leaderboard Points]

Main Features

Google login with Supabase Auth.

Terms of Use and Privacy Policy acceptance.

Tutorial/onboarding screens.

Countdown study timer.

Presets: 25 minutes, 50 minutes, 2 hours, and custom timer.

XP system based on real focused minutes.

Character leveling from Level 1 to Level 50.

20 coins rewarded on every level clear.

50 starting coins for new users.

Store for original characters, backgrounds, timer skins, and reward animations.

Daily challenges.

Daily and weekly rankings.

Profile screen with study stats.

Supabase Storage for image assets.

App Flow

flowchart TD
    A[Open App] --> B[Splash Screen]
    B --> C{Logged In?}
    C -- No --> D[Google Login]
    C -- Yes --> E{Terms Accepted?}
    D --> E
    E -- No --> F[Terms and Privacy Screen]
    E -- Yes --> G{Tutorial Completed?}
    F --> G
    G -- No --> H[Tutorial Screens]
    G -- Yes --> I[Main App]
    H --> I
    I --> J[Focus Timer]
    I --> K[Characters]
    I --> L[Store]
    I --> M[Challenges]
    I --> N[Ranking]
    I --> O[Profile]

Game Loop

stateDiagram-v2
    [*] --> ChooseTimer
    ChooseTimer --> FocusRunning: Start
    FocusRunning --> Paused: Pause
    Paused --> FocusRunning: Resume
    FocusRunning --> FinishedEarly: Finish Early
    FocusRunning --> Completed: Timer Reaches Zero
    FinishedEarly --> SaveSession
    Completed --> SaveSession
    SaveSession --> CalculateXP
    CalculateXP --> UpdateCharacter
    UpdateCharacter --> LevelReward
    LevelReward --> UpdateChallenges
    UpdateChallenges --> UpdateRanking
    UpdateRanking --> RewardSummary
    RewardSummary --> ChooseTimer

Architecture

flowchart TB
    subgraph Mobile App
        A[Flutter UI]
        B[Riverpod State]
        C[Services Layer]
        D[Local Cache]
    end

    subgraph Supabase
        E[Auth: Google Login]
        F[Postgres Database]
        G[Storage Buckets]
        H[RLS Policies]
    end

    subgraph Later
        I[Next.js Landing Page]
        J[Privacy Policy]
        K[Terms of Use]
        L[Admin Panel]
    end

    A --> B
    B --> C
    C --> E
    C --> F
    C --> G
    F --> H
    I --> J
    I --> K
    I --> L

Tech Stack

Layer

Tool

Mobile app

Flutter

State management

Riverpod

Routing

go_router

Auth

Supabase Auth with Google

Database

Supabase Postgres

Image storage

Supabase Storage

Legal pages

Next.js, Vercel, GitHub Pages, or Render Static Site

Version control

GitHub

Authentication Flow

sequenceDiagram
    participant User
    participant Flutter
    participant Supabase
    participant Google
    participant DB as Supabase DB

    User->>Flutter: Tap "Continue with Google"
    Flutter->>Supabase: Start Google OAuth
    Supabase->>Google: Redirect to Google Login
    Google->>Supabase: Return OAuth callback
    Supabase->>Flutter: Auth session created
    Flutter->>DB: Check profile
    alt New user
        Flutter->>DB: Create profile with 50 coins
    else Existing user
        Flutter->>DB: Load profile
    end
    Flutter->>DB: Check terms and tutorial status
    Flutter->>User: Route to next screen

XP, Coins, and Levels

Starting Rules

New user starts with 50 coins.

User profile starts at Level 1.

Each character starts at Level 1.

Initial max level: 50.

Each character level clear gives 20 coins.

Coins are used for cosmetic unlocks, not ranking advantage.

XP Formula

base_xp = actual_focused_minutes

if timer_completed:
  xp = base_xp * 1.2
else:
  xp = base_xp

Example

Session

Actual Time

Completed?

XP

Short focus

25 min

Yes

30 XP

Deep focus

120 min

Yes

144 XP

Early finish

18 min

No

18 XP

Characters and Evolutions

Characters must be original anime-inspired characters. Do not copy real anime, Marvel, DC, movie, cartoon, or game characters.

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

Evolution Unlocks

Form

Unlock Level

Form 1

Level 1

Form 2

Level 10

Form 3

Level 20

Form 4

Level 35

Form 5

Level 50

Example Characters

Shadow Ninja Student

Flame Sword Learner

Galaxy Scholar

Cyber Monk

Storm Runner

Crystal Mage

Dragon Exam Master

Neon Samurai

Forest Guardian

Star Captain

Store System

Store categories:

Characters

Backgrounds

Timer skins

Reward animations

flowchart TD
    A[Open Store] --> B[Select Category]
    B --> C[View Item]
    C --> D{Owned?}
    D -- Yes --> E[Equip Item]
    D -- No --> F{Enough Coins?}
    F -- No --> G[Show Insufficient Coins]
    F -- Yes --> H[Buy Item]
    H --> I[Deduct Coins]
    I --> J[Add to Inventory]
    J --> E

Example Store Prices

Item

Category

Price

Rookie Student

Character

Free

Shadow Ninja Student

Character

100 coins

Cozy Desk

Background

Free

Rainy Window

Background

80 coins

Neon Room

Background

150 coins

Classic Circle

Timer Skin

Free

Fire Ring

Timer Skin

100 coins

Galaxy Timer

Timer Skin

180 coins

Daily Challenges

Daily challenges should make users return without making the app stressful.

Examples:

Study 25 minutes today.

Complete 2 focus sessions.

Study 120 minutes total today.

Complete one session without pause.

Level up any character.

Use a new background.

flowchart LR
    A[New Day] --> B[Assign Daily Challenges]
    B --> C[User Studies]
    C --> D[Update Challenge Progress]
    D --> E{Challenge Complete?}
    E -- No --> C
    E -- Yes --> F[Claim Reward]
    F --> G[Add XP or Coins]
    G --> H[Add Rank Points]

Ranking System

MVP ranking types:

Daily ranking

Weekly ranking

Later:

Friends ranking

Group/class ranking

Seasonal global ranking

Ranking Formula

rank_points = focused_minutes + challenge_bonus + streak_bonus

Important rule: paid coins or store purchases should not improve ranking. Ranking should depend on real study activity.

Database Design

erDiagram
    auth_users ||--|| profiles : owns
    profiles ||--o{ terms_acceptance : accepts
    profiles ||--o{ user_characters : owns
    profiles ||--o{ user_inventory : owns
    profiles ||--o{ study_sessions : creates
    profiles ||--o{ user_daily_challenges : progresses
    profiles ||--o{ store_purchases : makes

    characters ||--o{ character_forms : has
    characters ||--o{ user_characters : unlocked_as
    characters ||--o{ study_sessions : used_in

    backgrounds ||--o{ user_inventory : unlocked_as
    timer_skins ||--o{ user_inventory : unlocked_as
    reward_animations ||--o{ user_inventory : unlocked_as

    daily_challenges ||--o{ user_daily_challenges : assigned_as

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
        timestamp created_at
        timestamp updated_at
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
        timestamp started_at
        timestamp ended_at
    }

Suggested Tables

profiles

terms_acceptance

characters

character_forms

user_characters

backgrounds

timer_skins

reward_animations

user_inventory

store_purchases

study_sessions

daily_challenges

user_daily_challenges

leaderboard views for daily and weekly rankings

Flutter Folder Structure

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

Required Accounts

Google account

GitHub account

Supabase account

Google Cloud project

Optional: Vercel, GitHub Pages, or Render for legal pages

Required Local Tools

Flutter SDK

Android Studio

VS Code

Git

Android emulator or Android phone

Java keytool through Android Studio JDK

Package Name

com.startupzilla.focussagaxp

Supabase Google Provider

Client IDs should be generated by Google Cloud. They look like:

1234567890-example.apps.googleusercontent.com

Do not paste the app name in the Client IDs field.

MVP Roadmap

gantt
    title FocusSaga XP MVP Roadmap
    dateFormat  YYYY-MM-DD
    section Foundation
    Flutter project setup      :a1, 2026-08-11, 2d
    Supabase setup             :a2, after a1, 2d
    Google login               :a3, after a2, 3d
    Terms and tutorial         :a4, after a3, 2d
    section Core App
    Focus timer                :b1, after a4, 3d
    Session saving             :b2, after b1, 2d
    XP coins levels            :b3, after b2, 3d
    Characters                 :b4, after b3, 4d
    Store                      :b5, after b4, 4d
    section Growth Features
    Daily challenges           :c1, after b5, 3d
    Ranking                    :c2, after c1, 3d
    Profile and polish         :c3, after c2, 3d

Milestones

Flutter project setup.

Theme and routing.

Supabase connection.

Google login.

Terms/privacy screen.

Tutorial screens.

Focus timer.

Study session saving.

XP, coins, and level logic.

Character system.

Store system.

Background and timer skin equip.

Daily challenges.

Ranking.

Profile screen.

Testing and release prep.

Future Monetization

The first launch should be free. Monetization should come only after validating that users return and complete sessions.

Possible future models:

Premium subscription for extra analytics, premium cosmetics, and streak tools.

Cosmetic coin packs.

Rewarded ads for optional bonus chests.

Parent/teacher plans for real-world reward tracking.

School/coaching dashboard.

Important: leaderboard rank should never be pay-to-win.

Legal and Content Rules

Use only original characters, names, forms, icons, and artwork.

Do not use:

Real anime characters

Real anime transformation names

Marvel characters

DC characters

Movie/game/cartoon characters

Protected logos or symbols

Safe approach:

Original anime-inspired characters

Original forms and powers

Original names

Original visual designs

Build in Public

Suggested public repo:

focussaga-xp

Suggested repo description:

A gamified study timer app where users earn XP, level up characters, unlock rewards, and build focus habits.

Suggested LinkedIn update:

I am starting to build FocusSaga XP, a gamified study timer app where users study with a countdown timer, earn XP, level up original characters, unlock rewards, and compete in daily challenges.

I am building the first free MVP with Flutter and Supabase.

The goal is simple: make focused study feel rewarding without making the app complex.

License

No license selected yet.
