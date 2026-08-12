# Milestone 23 — Final MVP Testing Checklist

Build: `flutter run` (debug) on a physical Android device. Retest the whole
sheet once more against `flutter run --release` (or the release APK) before
handing over for review. Use a clean Supabase project where possible, or
delete test users from Dashboard → Authentication → Users between onboarding
runs.

Checklist keys:
- `[ ]` = test item (check off when the expected result matches)
- Items are ordered to mirror the first-run journey.

---

## 0. Test environment

- [ ] App is signed in on a physical device (emulator is NOT reliable for
      OAuth / deep links / background timers).
- [ ] Supabase project `rychyralxfvhljsmlmkp` reachable from the device
      (`https://rychyralxfvhljsmlmkp.supabase.co`).
- [ ] A second Google account is available to retest onboarding without
      deleting the primary test user.

---

## 1. Google login

- [ ] Fresh install → app opens on the Login screen (no crash, splash → login).
- [ ] "Sign in with Google" opens an external browser / Chrome Custom Tab.
- [ ] After choosing an account, control returns to the app automatically
      (deep link `com.startupzilla.focussagaxp://callback`).
- [ ] No "Unable to exchange code" / 403 errors after the browser returns.
- [ ] Cancelling the Google account picker returns you to the app, not a
      dead browser tab.
- [ ] Logging in twice in a row (logout → login) requires no re-consent
      beyond Google's normal flow.

## 2. Profile creation

- [ ] First login → a profile row is created automatically (no error snackbar).
- [ ] Dashboard check:
      `select user_id, display_name, email, avatar_url, coins, profile_level,
              tutorial_completed
         from profiles order by created_at desc limit 1;`
      → `coins = 50`, `profile_level = 1`, `tutorial_completed = false`,
      Google name/email/avatar filled in.
- [ ] `grant_starter_items` fired: the user owns the starter character.
      `select count(*) from user_characters where user_id = auth.uid();` → ≥ 1
      (plus any starter inventory rows in `user_inventory`).
- [ ] Logging out and back in with the SAME account does NOT reset coins
      or level (the existing row is reused, not re-created).

## 3. Terms acceptance

- [ ] After first login the app lands on the Terms screen (not the app).
- [ ] Accepting writes to `terms_acceptance` and the app proceeds without
      a manual refresh.
- [ ] After accepting, the app never shows the Terms gate again (even after
      logout/login).
- [ ] Quitting the app on the Terms screen and reopening stays on Terms.

## 4. Tutorial completion

- [ ] After terms, the app lands on the Tutorial screen.
- [ ] Finishing the tutorial sets `tutorial_completed = true` and lands on
      the Focus tab.
- [ ] Re-login afterwards skips the tutorial entirely.
- [ ] Backgrounding the app mid-tutorial and returning does not crash or
      skip ahead.

## 5. Timer

- [ ] Focus tab shows presets (25 min / 50 min / 2 h) + custom duration,
      and the countdown starts on Start.
- [ ] A 25-minute session's XP preview matches the rules
      (1 XP/min + 20% completion bonus = 30 XP for 25 min).
- [ ] Timer counts down accurately over 2+ minutes (compare with a wall
      clock; no drift).
- [ ] **Background test:** start a session, home-button out for 60 s, reopen —
      elapsed time includes the background 60 s (wall-clock catch-up), and
      the app did not hang or restart.
- [ ] **Complete-in-background test:** start a 5-minute session, background
      the app past zero, reopen → session shows completed and the reward
      recap appears once.
- [ ] Sessions longer than 3 hours are rejected (max session = 3 h).
- [ ] Timer cannot be started twice (Start is disabled while running).

## 6. Pause / resume

- [ ] Pause freezes the remaining time; elapsed does not grow while paused.
- [ ] Resume continues from the same remaining time (no jump).
- [ ] Pausing and resuming repeatedly keeps the count accurate and records
      `paused_count` (stats).
- [ ] Pause while the app is backgrounded → reopen → still paused, no time
      accrued while paused.
- [ ] Pause then press "Finish" ends the session with paused state handled
      correctly (no crash, reward reflects studied minutes only).

## 7. Finish early

- [ ] "Finish" ends the session before zero without error.
- [ ] Reward recap shows XP for ACTUAL studied minutes only (no +20%
      completion bonus).
- [ ] The saved session has `completed = false` in `study_sessions`.
- [ ] Behavior note (intended): early-finished sessions do NOT extend the
      daily streak (`current_streak` counts only `completed` sessions) but
      DO count toward leaderboard focused minutes.

## 8. XP / coins / levels

- [ ] Full session reward recap matches the database afterwards:
      `select coins, profile_level from profiles where user_id = auth.uid();`
      and
      `select xp from user_characters where user_id = auth.uid() and is_selected;`
- [ ] XP is applied to the EQUIPPED character (not a random one).
- [ ] Level-up grants +20 coins per level gained and the recap shows
      "levels!" text (rule: 100 XP per level, cap 50).
- [ ] No double-award: the reward dialog appears exactly once even if you
      rotate the phone or background the app right after completion
      (`session_saved` guard).
- [ ] Offline / API error during save shows an error and does NOT fake the
      reward (session stays unsaved, no coins lost).

## 9. Character equip

- [ ] Characters tab lists owned characters with the equipped one flagged.
- [ ] Equipping character B un-equips A — exactly ONE `is_selected = true`
      row afterwards:
      `select count(*) from user_characters where is_selected;` → 1
- [ ] Equipped state survives app restart (server-side, not local).
- [ ] Equipping a character you do NOT own fails with a friendly message
      (RPC rejects).
- [ ] Profile tab Companion card shows the newly equipped character after
      navigating there.

## 10. Store purchase

- [ ] Store lists all four categories (characters, backgrounds, timer skins,
      reward animations) with prices.
- [ ] Buying an affordable item deducts coins and shows the new balance
      (`balance` returned by `buy_store_item` matches
      `select coins from profiles where user_id = auth.uid();`).
- [ ] Buying the SAME item twice is rejected (no double deduction).
- [ ] Buying with insufficient coins is rejected with a clear message and
      coins stay unchanged.
- [ ] Items locked by player level show the required level and cannot be
      bought below it.
- [ ] Equipping a purchased background / skin / animation works and shows
      as equipped in the store; re-equipping another of the same category
      swaps cleanly.
- [ ] Double-tapping Buy does not create duplicate purchases (button
      disabled while pending).

## 11. Daily challenges

- [ ] Challenges tab loads 3 challenges for today automatically
      (`refresh_daily_challenges` assigns + recomputes live progress).
- [ ] Completing a session updates challenge progress on the challenges tab
      (invalidate after save).
- [ ] Fully meeting a challenge shows "Claim reward"; claiming shows the
      reward dialog with coins + XP + rank points.
- [ ] Claiming twice shows the friendly "Reward already claimed" error.
- [ ] New day (or UTC midnight — 5:30 AM IST) refreshes the challenge set
      for the new date.
- [ ] Claimed challenge's rank points appear on the leaderboard.
- [ ] Date-boundary note (intended): "today" is UTC — a challenge may flip
      at 5:30 AM local time in IST; do not file this as a bug.

## 12. Leaderboard

- [ ] Ranking tab shows Daily and Weekly tabs.
- [ ] With at least one other test user + sessions: rows show rank, avatar,
      username, level, focused minutes, rank points.
- [ ] Your row is highlighted (colored background + "You" pill).
- [ ] After finishing a session, pull-to-refresh moves your row/points up.
- [ ] Streak bonus adds 10 points per streak day (cap 300) and the streak
      shows on the row.
- [ ] Weekly tab shows the rolling 7-day window (yesterday's daily work
      still counts this week).
- [ ] Empty state renders correctly for a fresh account with no sessions.
- [ ] Loading spinner appears on first open; error state offers Retry when
      offline.

## 13. Logout / login again

- [ ] Logout returns to the Login screen.
- [ ] Re-login (same account) restores: coins, level, character, inventory,
      challenges, sessions — nothing reset.
- [ ] Re-login skips Terms and Tutorial gates.
- [ ] Kill the app while logged in → relaunch → lands straight on the app
      (session restore), not Login.
- [ ] Kill the app while logged OUT → relaunch → Login screen.
- [ ] Switching accounts preserves each account's separate data (no bleed).

## 14. Android release build

Prereq: `build.gradle.kts` currently signs release builds with the DEBUG key
(`signingConfig = signingConfigs.getByName("debug")` at line 31) — fine for
a `flutter run --release` smoke test, but do NOT upload that to the Play
Store without a real upload keystore (see fixes below).

- [ ] `flutter build apk --release` completes with no errors.
- [ ] Release APK installs on a device (uninstall the debug build FIRST —
      signature mismatch otherwise).
- [ ] Full login flow works in the release build (OAuth + deep link).
- [ ] App icon is not the default Flutter logo (replace before store).
- [ ] `flutter build appbundle --release` produces `app-release.aab`.
- [ ] `versionCode` / `versionName` in `pubspec.yaml` are bumped for the
      first store upload.
- [ ] Internet permission present in the release manifest (INTERNET is in
      `AndroidManifest.xml` — verify it survived any manifest edits).
- [ ] Release build does not leak debug tooling (no debug banner, no
      `localhost` endpoints in the app config).

---

## Common bugs & fixes

### Google login

| Symptom | Cause | Fix |
|---|---|---|
| "Unable to exchange code" / 403 after Google returns | Redirect URL not registered | Supabase Dashboard → Authentication → URL Configuration → add `com.startupzilla.focussagaxp://callback` to **Redirect URLs** (or set to `Allow all` temporarily) |
| Login works in debug, fails in release | None of the standard reasons apply with PKCE — check you didn't accidentally point the release build at a different `SUPABASE_URL` via `--dart-define` | Compare `--dart-define` flags between builds; verify `AppConfig` values in both |
| Browser returns but app stays on Login (blank activity) | Deep link not reaching the app | Verify the intent-filter exists in the MAIN manifest (it does — `android/app/src/main/AndroidManifest.xml:29-36`); test with `adb shell am start -a android.intent.action.VIEW -d "com.startupzilla.focussagaxp://callback"`; do NOT remove `launchMode="singleTask"` or `taskAffinity=""` |
| Google account picker never opens / spinner forever | Network or OAuth client misconfig on Supabase's Google provider | Dashboard → Authentication → Providers → Google: client ID + secret set and provider enabled |

### Profile creation

| Symptom | Cause | Fix |
|---|---|---|
| Coins/level reset on re-login | Profile row deleted (or user deleted in dashboard) then re-created | `ensureProfile` re-uses the existing row; if values reset, the row really was gone — check `profiles` for the user |
| User has no starter character | `grant_starter_items` trigger didn't fire (e.g. profile created before the trigger existed) | Run `select grant_starter_items(p_user_id) from ...` for the affected user or insert via the RPC `grant_starter_items` |
| "duplicate key value violates unique constraint" during sign-in | Race: two simultaneous `ensureProfile` inserts | Only relevant on fast double-login; otherwise harmless (insert is preceded by a fetch) |

### Terms / tutorial

| Symptom | Cause | Fix |
|---|---|---|
| Stuck on Terms after accepting | `termsStatusProvider` / `currentProfileProvider` not invalidated after the write | Invalidate both providers right after `acceptTerms` / `completeTutorial` |
| Tutorial gate reappears after re-login | `tutorial_completed` never written (RPC/update failed silently) | Check `profiles.tutorial_completed`; the update is `eq('user_id', ...)` — confirm the row's key is `user_id`, not `id` |

### Timer / pause / finish

| Symptom | Cause | Fix |
|---|---|---|
| Time jumps forward after backgrounding | Intended wall-clock behavior | Not a bug — elapsed is computed from timestamps; test with a stopwatch |
| Reward dialog appears twice | Save guard missing | The controller sets `sessionSaved` and FocusTab checks it before saving; if duplicated, `markSessionSaved` isn't being called — save path bug |
| Session lost when app is killed (swiped away) mid-run | In-progress sessions are not persisted locally (MVP limitation) | Known limitation — document; future: persist `startedAt` and reconcile on launch |
| Timer completes while paused | `_catchUp` not called when paused | Not possible in current code (ticker cancelled on pause) — if it happens, a second ticker is running; fix `pause()` to also cancel the lifecycle catch-up |

### XP / coins

| Symptom | Cause | Fix |
|---|---|---|
| XP applied to wrong character | No character selected → RPC used a fallback / null | Select a character before saving sessions; `save_study_session` takes `p_character_id` |
| Coins don't match recap | Level-up coins computed client-side differently | Recap shows what the RPC returned — trust the server values; reconcile with `select coins from profiles` |
| 0 XP for a 1-minute session | XP is per-minute with integer truncation (`actualMinutes * 1`) | Expected — a 30-second early finish yields 0 XP |

### Store / equip

| Symptom | Cause | Fix |
|---|---|---|
| Item shows as owned but not equipped after restart | `is_equipped` on `user_inventory` row | Verify via `select * from user_inventory;` — `equip_inventory_item` should set exactly one per `(user_id, item_type)` |
| Negative coins after rapid purchases | RPC re-entry / double-tap | `buy_store_item` checks balance in a transaction; if coins go negative, report the RPC's balance check |
| Can't equip a purchased background | `item_type` mismatch between store value and RPC expectation | `kind.apiValue` must match the `item_type` check in `buy_store_item`/`equip_inventory_item` (e.g. `background`, not `backgrounds`) |

### Challenges

| Symptom | Cause | Fix |
|---|---|---|
| Progress stuck at 0 after a session | Progress is recomputed by `refresh_daily_challenges` from live data | Pull-to-refresh the Challenges tab (provider invalidate) — the RPC recomputes |
| "already claimed" on first claim | The row's `claimed` flag was set by an earlier claim | Check `user_daily_challenges` for the row; double claims are intentional rejects |
| Challenges empty after midnight | UTC date boundary | Refresh after 5:30 AM IST; the RPC assigns challenges for `current_date` (UTC) |

### Leaderboard

| Symptom | Cause | Fix |
|---|---|---|
| You don't appear on the board | No profile row OR no sessions today | The view joins from `profiles` — every user appears even with 0 minutes; verify the profile exists |
| Row shows level 1 for everyone | `profile_level` column missing from the view | The view now selects `p.profile_level` — if it regressed, re-run the view DDL (M20/M21) |
| Streak shows 0 after a full session | Streak requires a COMPLETED session (`completed = true`) | Early finishes don't count — finish a session to zero to extend the streak |

### Logout / login again

| Symptom | Cause | Fix |
|---|---|---|
| App still shows previous user's data after logout | Providers not reset when `authUserProvider` flips to null | All feature providers watch `authUserProvider` and return empty — if stale data persists, the provider is missing the `authUserProvider` watch |
| Relaunch after logout logs straight back in | Session restore from secure storage | Expected with Supabase persistence; "logout" truly clears it via `signOut()` |

### Android release build

| Symptom | Cause | Fix |
|---|---|---|
| `INSTALL_FAILED_UPDATE_INCOMPATIBLE` when installing release over debug | Different signatures (release is debug-signed too, but installs conflict across variants) | `adb uninstall com.startupzilla.focussagaxp` before installing the other variant |
| Release signed with debug key | `build.gradle.kts:31` intentionally uses the debug config | For Play: create an upload key — `keytool -genkey -v -keystore upload-keystore.jks -alias upload -keyalg RSA -keysize 2048 -validity 10000`, then add `signingConfigs { create("release") { ... } }` and reference it; enable Play App Signing so only the upload key is required |
| Google login broken ONLY in release | Supabase URL/key differs (dart-define) or the redirect host is unreachable in release | Confirm the release uses the same `SUPABASE_URL` / key as debug; test the deep link with `adb shell am start` |
| R8 shrunk away classes (only if `minifyEnabled true` is added) | Flutter templates ship with minify off — do not enable without rules | Keep minify disabled, or add keep rules for `supabase_flutter` / generated models if you enable it |
| `flutter build appbundle` fails with NDK/AGP errors | NDK version mismatch on the machine | `build.gradle.kts` pins `ndkVersion = flutter.ndkVersion` — run `flutter upgrade` + `flutter clean` to resync |
| Manifest edits don't take effect | Stale build | `flutter clean` then rebuild |

---

## Pre-release gate (run once, after all of the above)

- [ ] Full journey on a fresh account: login → profile → terms → tutorial →
      session → early finish → level-up → equip → buy → challenge →
      leaderboard → logout → login.
- [ ] Full journey in the RELEASE build (debug-signed release APK is fine
      for the smoke test).
- [ ] No crash in 30 minutes of mixed usage (timer + background + tabs).
- [ ] Version bumped in `pubspec.yaml`.
