# Performance & Stability Optimization Plan

Goal: make FocusSaga XP fast and stable with many users and on low-end
Web/Android, using only Supabase (no load balancer / custom server yet).

## Baseline (audited)

- Supabase project: `rychyralxfvhljsmlmkp`, anon-key app, PostgREST + RPCs.
- All DB indexes already exist (verified against live `pg_indexes`):
  - leaderboards: `study_sessions_ended_at_idx`, `study_sessions_user_ended_idx`,
    `study_sessions_user_completed_ended_idx`, `udc_date_claimed_idx`,
    `profiles_coins_idx`, `profiles_level_idx`
  - streak: `study_sessions_user_completed_ended_idx` (user_id, completed, ended_at)
  - challenges: `uqdc_user_date_idx` (user_id, challenge_date desc, is_completed)
  - store/purchases: `uq_user_inventory_owner`, `uq_user_characters_owner`,
    `store_purchases_user_idx`, `store_purchases_date_idx`
  - master data: `character_forms_char_idx`, unique name keys
- No new migration is required for the work below. (If a new table/column is
  added later, re-check with `pg_indexes` first.)
- Riverpod 2 `FutureProvider`s are non-autoDispose → already session-long
  cached; they refetch only on `invalidate` (every mutation point invalidates
  correctly today).

## Risks found (app level)

1. `ranking_repository.fetchDaily/fetchWeekly` → `.select()` with **no limit**.
   The `daily_leaderboard` view scans every profile and runs a per-user
   `current_streak()` lateral call → unbounded work + payload with many users.
2. `profile_repository.fetchTotalFocusedMinutes` downloads **every**
   `study_sessions` row for the user and sums in Dart. Should be a server-side
   `SUM`.
3. `progress_repository.saveSession` (the most critical write) has **no
   `guardNetwork` timeout** — a stalled request spins the Save button forever.
4. `ensureProfile` runs the `ensure_starter_items_for_current_user` RPC on
   **every** profile load/invalidate (1 extra RPC per load; profile is
   invalidated on every save/claim/buy).
5. `storeCatalogProvider` refetches **6 parallel queries** on every
   invalidation (buy/equip), although 4 of them read static master tables.
6. `selectedCharacterProvider` re-runs the full characters+forms nested query
   alongside `ownedCharactersProvider` → the same join is fetched twice.
7. Missing `guardNetwork` on: `hasAcceptedTerms`, `acceptTerms`,
   `completeTutorial`, `fetchCurrentStreak`, `fetchTotalFocusedMinutes`,
   `updateDisplayName`, `challenge_repository.claim`,
   `store_repository.buy/equip`, `character_repository.equip`.

## Changes

### 1. Leaderboard: bounded read (biggest win)
`ranking_repository.dart` — add `.limit(50)` + explicit
`.order('rank_points', ascending: false)` to both fetches. UI keeps top-50 +
"You" highlight; no pagination UI (top-50 is the product).

### 2. Total focused minutes: server-side SUM
`profile_repository.fetchTotalFocusedMinutes` — use PostgREST aggregate
`select('actual_minutes.sum()')` + `maybeSingle()`, with a fallback to the old
row-fold on any error so the stat never breaks.

### 3. Timeouts everywhere (no infinite spinners)
Wrap every remaining repo call in `guardNetwork` (15 s): `saveSession`,
`hasAcceptedTerms`, `acceptTerms`, `completeTutorial`, `fetchCurrentStreak`,
`fetchTotalFocusedMinutes`, `updateDisplayName`, `claim`, `buy`, `equip`
(character + store).

### 4. Starter repair: once per app session
`ProfileRepository` keeps a per-user-id flag; `ensureProfile` runs
`ensure_starter_items_for_current_user` only on the first load of the session
(repair is idempotent; every later load skips it). Manual "Restore starter
kit" button still always runs it.

### 5. Store master data: session-long cache
`StoreRepository` caches the 4 master-table fetches (characters, backgrounds,
timer_skins, reward_animations — all `active`, static data) for the app
session. `fetchCatalog` after a buy/equip then runs only the 2 user-scoped
queries (inventory + user_characters). Cache is rebuilt on cold start.

### 6. Selected character: derived, not re-fetched
`selectedCharacterProvider` becomes a derived `Provider<AsyncValue<OwnedCharacter?>>`
that reuses `ownedCharactersProvider` (which orders `is_selected` first). The
characters+forms join is fetched once, not twice. All current consumers use
`.value`/`.when`/`ref.listen`/`invalidate` — compatible.

### 7. UI polish (no crash / no blank spots)
- Focus tab: while the selected character is loading or errored, show the
  `CharacterPlaceholderTile` instead of nothing.
- Profile tab: companion card error state gets a Retry button (invalidates
  `ownedCharactersProvider`); pull-to-refresh invalidates the derived source.

## Explicitly NOT doing (avoid over-engineering)

- No materialized views / pg_cron refreshes (data is per-day small; views are
  fine at this scale).
- No TTL polling providers — every mutation already invalidates; pull-to-refresh
  covers staleness; TTL would add background requests and error-flicker offline.
- No leaderboard pagination UI beyond top-50.
- No load balancer / Node.js sidecar / Redis / rate limiting yet — document
  the future path instead: Render/Railway/Fly.io Node.js service + Nginx/LB +
  Redis cache + rate limiting, then horizontal scale.
- No local persistence of master data (SharedPreferences/Isar) — session cache
  suffices; revisit if offline mode becomes a requirement.

## Concurrency / atomicity (already correct, re-verified)

- `save_study_session`, `buy_store_item`, `equip_*`, `claim_challenge_reward`,
  `refresh_daily_challenges`, `ensure_starter_items_for_current_user` are all
  single-transaction server RPCs.
- Duplicate purchases blocked by `uq_user_inventory_owner` /
  `uq_user_characters_owner`; double claims blocked by `claimed` check in
  `claim_challenge_reward`; coins ≥ 0 enforced in RPCs.
- Timer `sessionSaved` flag + `_saving` re-entrancy guard prevent double saves.

## Validation checklist

1. `flutter analyze` clean.
2. Full test suite (`flutter test`) green — current baseline 61/61.
3. `flutter run -d chrome --web-port 50068`: log in, complete a short session,
   check reward screen, challenge claim, buy+equip in store (confirm only
   2 queries on re-open), leaderboard shows top-50, profile stats load.
4. Kill network mid-save → SnackBar + retry (not infinite spinner).
5. Android phone smoke test if available.
