# Date Dawn — Fix Checklist

What was wrong, what was changed, and how to confirm it. Every item is
implemented in this branch; the "Verify" column is what to look at.

---

## 1. Slow loading

| # | Problem | Fix | Verify |
|---|---|---|---|
| 1.1 | `main()` **awaited** `Supabase.initialize` before `runApp`, so every cold start waited on a network round-trip to a *secondary* backend (theme sync, inbox, avatars). If Supabase was slow or down, the app never mounted. | Supabase now initialises **in the background** with an 8s timeout. The first frame no longer waits on it; failures are logged and the app continues Firestore-only. | `lib/main.dart` → `_initSupabase()`; the app renders countdowns before Supabase resolves. |
| 1.2 | Shared-event fetch ran its `whereIn` chunks **sequentially** — one round-trip per 30 events. | Chunks now run in **parallel** via `Future.wait`, with a re-entrancy guard so the two feeds don't duplicate work. | `event_repository.dart` → `fetchShared()`. |
| 1.3 | The participant feed **overwrote** `latestSharedIds`, dropping circle-shared ids whenever it re-emitted, so shared countdowns flickered. | The sets are now **unioned**. | `event_repository.dart` → `subShared`. |
| 1.4 | The first emission was often `[]` (owned feed fires before the shared/circle feeds answer), so the home screen flashed "nothing here" on every load. | Empty first emissions are **held back**; a 600 ms settle forces the empty state for a genuinely empty account. | `event_repository.dart` → `emit()` / `subOwned`. |
| 1.5 | `eventsProvider` returned `Stream.empty()` while the session restored — a stream that **completes**, dropping the provider out of `loading`. | It now returns a stream that never emits until auth resolves, so the UI stays on its spinner instead of flashing empty. | `app_providers.dart` → `_neverEmits()`. |
| 1.6 | Home only showed its spinner during auth load, not while the events feed was re-subscribing. | The spinner is held until the feed produces a value (or a genuine empty list). | `home_screen.dart`. |

## 2. Invitation error message

| # | Problem | Fix | Verify |
|---|---|---|---|
| 2.1 | The self-invite refusal read `"Can't invite yourself lol"` — unprofessional. | Replaced with a single shared constant: **`You cannot invite yourself — you are already on this.`** Used by both the countdown and circle flows. | `event_repository.dart` → `cannotInviteSelfMessage`. |
| 2.2 | The message only appeared as a transient snackbar. | It now renders as **red inline text** under the invite field, in both the editor and the circle invite sheet. | `event_editor_screen.dart`, `circles_screen.dart`. |

## 3. Database ("isn't working")

| # | Problem | Fix | Verify |
|---|---|---|---|
| 3.1 | **Nothing ever wrote to the Supabase `notifications` table.** `sendNotification` existed but had no callers, so the inbox was permanently empty. | Invitations, acceptances, declines and circle joins now write an inbox row through an injected `notificationSink`. | `event_repository.dart` → `_notify()`; `app_providers.dart` → `notificationSink`. |
| 3.2 | A write before Supabase finished initialising would throw on a half-built client. | Added `SupabaseService.isReady`; the sink and profile sync are gated on it. | `supabase_service.dart` → `isReady` / `markReady()`. |
| 3.3 | A missing `notifications` table (schema not applied) made every send throw. | `sendNotification` now **swallows and logs** failures — notifications ride on an already-committed Firestore write. | `supabase_service.dart` → `sendNotification`. |
| 3.4 | Invites to **existing users** never resolved to an account, so they sat unclaimed. | `inviteByEmail` now calls `lookupUserByEmail` and writes the participant row directly. | `event_repository.dart` → `inviteByEmail`. |
| 3.5 | `lookupUserByEmail` stringified missing fields to the literal `"null"`. | Returns only fields that are actually present. | `event_repository.dart` → `lookupUserByEmail`. |
| 3.6 | **Couple circles never auto-shared** — the composer got a circle document without its `members`, so the loop iterated an empty list. | Members are hydrated on demand from the `members` subcollection. | `event_repository.dart` → `createEvent`. |

### Deploy the database pieces (one-time, from the project root)

Firestore rules and indexes are the authority for the countdown data:

```bash
firebase deploy --only firestore:rules,firestore:indexes
```

Supabase owns theme sync, the inbox and avatars. Apply the schema once:

```bash
# Supabase dashboard → SQL editor → paste supabase/schema.sql → Run
```

Without the indexes, Firestore rejects the shared-events queries (the app
appears to "lose" shared countdowns). Without the Supabase schema, the inbox
stays empty and avatar upload fails — the app logs those and keeps working.

## 4. Interaction feedback

| # | Problem | Fix | Verify |
|---|---|---|---|
| 4.1 | Back arrows had no hover/press feedback. | New `DangerHoverIconButton`: the icon turns **red on hover (mouse) and press (touch)**, easing back. Applied to every back arrow. | `widgets/brand_kit.dart`. |
| 4.2 | Same for circles and invitations. | The Circles / Invitations / Notifications top-bar icons and the circle invite action use the same treatment. | `home_screen.dart`, `circles_screen.dart`. |

## 5. Navigation

| # | Problem | Fix | Verify |
|---|---|---|---|
| 5.1 | Creating a countdown left you on the editor; you had to press Back to see it. | Saving pins the new countdown as the hero and returns **straight to Home**, with the stack reset so Back never bounces into the composer. | `event_editor_screen.dart` → `_save()`. |

---

## Verification status

| Check | Result |
|---|---|
| `flutter analyze` | No issues |
| `flutter test` | 68/68 passing (incl. self-invite + couple auto-share regressions) |
| `flutter build web` | Compiles cleanly |

### Not verifiable from here

The live Firebase/Supabase behaviour on your deployed project. The repository
is tested against an in-memory fake; the real indexes, rules and Supabase
schema must be deployed with the commands in §3. If something still fails after
deploying, the log line will name it (`[datedawn] Could not write a Supabase
notification: …`).