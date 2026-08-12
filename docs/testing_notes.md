# Testing Notes and Known Decisions

## Intended Product Rules

- Streaks count only sessions where `completed = true`.
- Early-finished sessions do not extend streaks.
- Early-finished sessions still count toward leaderboard minutes.
- XP formula: `1 XP per focused minute`.
- Full timer completion gives `+20% XP bonus`.
- Character level requirement: `100 XP per level`.
- Each level clear gives `+20 coins`.
- Max session length is `3 hours`.
- Character level cap is `50`.
- `session_saved` prevents double reward dialogs.
- `grant_starter_items` is expected on first signup:
  - `50 coins`
  - starter character
  - starter background
  - starter timer skin

## Common Bugs and Fixes

| Area | Bug | Fix |
|---|---|---|
| Google Login | `403 unable to exchange code` | Add `com.startupzilla.focussagaxp://callback` in Supabase Auth redirect URLs |
| Auth Routing | Stuck on Terms/Tutorial after accepting | Invalidate auth/profile/tutorial providers after update |
| Android Install | Release install fails over debug | Run `adb uninstall com.startupzilla.focussagaxp` first |
| Release Signing | Release signed with debug key | Create release keystore and configure Play App Signing |
| Deep Links | Login callback stops working | Do not remove `launchMode="singleTask"` or `taskAffinity=""` |
| Rewards | Double reward dialog | Keep `session_saved` guard |
| Signup | New user missing starter items | Check `grant_starter_items` trigger |

## Deep Link Test

```bash
adb shell am start -a android.intent.action.VIEW -d "com.startupzilla.focussagaxp://callback"
```

Expected: the app opens on the Login screen (or the already-authenticated
session is restored) with no error — confirms the callback intent-filter,
`singleTask` launch mode and `taskAffinity=""` are intact.
