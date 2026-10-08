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

> **Root cause found (verified against the live project):** the Cloud Firestore
> API was **never enabled** in the `datedawn` Firebase project, and the Supabase
> schema was **never applied**. No code change could have fixed the persistence
> problem on its own — there was no database to write to. Run
> `node scripts/check-backend.mjs` to see the current state, then enable
> Firestore and run `supabase/schema.sql` once.

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
---

# 6. Migration: Firebase Auth + Supabase data

Identity stays on Firebase. All countdown data now lives in Supabase Postgres.

| Concern | Before | Now |
|---|---|---|
| Sign-in | Firebase Auth | **Firebase Auth** (unchanged) |
| Countdowns, circles, invitations, notes | Cloud Firestore | **Supabase Postgres** |
| Notification inbox, theme sync, avatars | Supabase | **Supabase** (now actually written to) |
| How Supabase knows who you are | `x-user-id` header (client-claimed) | **Verified Firebase ID token** |

## The identity bridge

`main.dart` gives the Supabase client an `accessToken` callback returning the
current Firebase ID token. Supabase verifies it against the Firebase project
registered under Third-Party Auth and exposes the Firebase uid as `auth.uid()`.

The old `x-user-id` header is **gone**. That mattered: it was a claim the client
made about itself, so any caller could have sent any uid. A token is a
signature-verified statement, so `auth.uid()` cannot be forged.

## Why RLS is now the whole security model

Authorisation lives in Postgres policies (`supabase/schema.sql`), not in client
code. The client cannot widen its own access — a crafted request is refused by
the database. That is a real improvement over the Firestore rules, which the
client had to mirror by hand.

## Performance

The old Firestore read merged **three** feeds client-side, and each shared event
cost a second round-trip after its id was discovered — a waterfall per load. The
new read is **one** query: the `events` RLS policy already means "I created it,
or I am an accepted participant, or it is shared with a circle I am in", and
Postgres applies it per row. Fewer round-trips, and no merge logic to get wrong.

## Files

| File | What it is |
|---|---|
| `lib/main.dart` | Supabase init with the `accessToken` callback |
| `lib/services/auth_service.dart` | Force-refreshes the ID token after sign-in so the `role` claim is present |
| `lib/services/event_repository.dart` | Rewritten against Postgres (was Firestore) |
| `lib/core/models.dart`, `lib/core/circles.dart` | Added `fromRow` parsers for the Postgres row shape |
| `supabase/schema.sql` | Tables, helpers, `auth.uid()` RLS, Realtime, storage |
| `firebase/functions/index.js` | Blocking Auth functions that stamp `role: 'authenticated'` |
| `firebase/functions/backfill-role.js` | One-off script for accounts that already exist |
| `scripts/check-backend.mjs` | Probes both backends, says what is missing |
| `scripts/validate-schema.mjs` | Parses the schema with the real Postgres grammar |

## Before it works — 3 dashboard steps

Run `node scripts/check-backend.mjs` at any point to see what is still missing.

**1. Register Firebase with Supabase.**
Supabase dashboard -> Authentication -> Third-Party Auth -> add Firebase ->
project id `datedawn`.
Without this Supabase cannot verify the token and every request is anonymous.

**2. Stamp the `role` claim (the one people miss).**
Firebase ID tokens carry no `role` claim, so Supabase assigns the `anon` Postgres
role — and every policy grants to `authenticated` only. The symptom is
`permission denied` on every query even though you are signed in.

```bash
cd firebase/functions
npm install
firebase deploy --only functions
```

Then, for accounts that already exist:

```bash
# Firebase console -> Project settings -> Service accounts -> Generate new private key
# Save as firebase/functions/service-account.json (gitignored - never commit it)
node backfill-role.js
```

**3. Run the schema.**
Supabase dashboard -> SQL Editor -> paste all of `supabase/schema.sql` -> Run.

## Verification

| Check | Result |
|---|---|
| `flutter analyze` | No issues found |
| `flutter test` | 74/74 passing |
| `dart format --set-exit-if-changed lib test` | exit 0 |
| `flutter build web` | `√ Built build\web` |
| `node scripts/validate-schema.mjs` | 146 statements, all valid SQL |

### What is NOT verified

- **The live backend.** I have no credentials for the Firebase or Supabase
  projects, so no query has been run against the real database. The row parsers
  and guard rails are unit-tested; the SQL is grammar-checked but never executed.
- **RLS under a real session.** The policies are derived from the Firestore rules
  that were the shipped authority, but no signed-in user has exercised them yet.

---

# 7. Reversal: everything back on Firebase

Supabase removed entirely. Auth, data, storage — all Firebase.

| Concern | Where it lives now |
|---|---|
| Sign-in | Firebase Auth |
| Countdowns, circles, invitations, notes | Firestore (`events`, `circles`, … ) |
| Notification inbox | **`users/{uid}/notifications/{id}`** subcollection, live listener |
| Theme sync | `users/{uid}.themeMode` |
| Avatars | **None** — initials drawn in Flutter (see § 8) |

## Removed

- `lib/services/supabase_service.dart`, `lib/supabase_config.dart`
- `supabase/schema.sql`, `firebase/functions/` (the role-claim functions)
- `supabase_flutter` and `flutter_dotenv` dependencies, the `.env` asset
- The `accessToken` callback and every `x-user-id` trace

## Added

- **`lib/services/notification_service.dart`** — the per-user data layer: the
  inbox and theme sync.
- `firestore.rules`: the inbox subcollection.

## Why the inbox is a subcollection

Notifications live at `users/{uid}/notifications/{id}`. The path itself carries
the recipient, so no rule has to trust a `userId` field on the document and a
query cannot span users by accident. Reads are owner-only; **creates are allowed
by any signed-in user**, because "your friend joined your circle" is written by
the friend, not the recipient. Updates are narrowed to the `read` flag alone.

## Avatar path convention

There isn't one any more. § 8 removed it.

## Verification

| Check | Result |
|---|---|
| `dart format --set-exit-if-changed lib test` | exit 0 |
| `flutter analyze` | No issues found |
| `flutter test` | **75/75 passing** |
| `flutter build web` | `√ Built build\web` |

## Backend status (probed live)

`node scripts/check-backend.mjs` →

- **Firebase Auth** — reachable
- **Firestore** — **live** (the earlier `SERVICE_DISABLED` is gone; an
  unauthenticated read now correctly returns `PERMISSION_DENIED`, which means
  the database exists and the rules are deployed)
- **Cloud Storage** — intentionally absent. § 8 removed avatars; no bucket is
  expected to exist, and `scripts/check-backend.mjs` no longer probes one.

### Still to do by hand

```bash
firebase deploy --only firestore:rules,firestore:indexes
```

**Do not skip this after § 9 or § 10.** The rules file changed; until it is
deployed, Accept on a circle invitation and creating a countdown both keep
returning `permission-denied`.

There is nothing to enable for Storage. See § 8.

### Note on Firestore indexes

`firestore.indexes.json` is intact and required — the shared-event queries need
the composite indexes, and Firestore rejects them without. If a query ever fails
with a link to create an index, that link is the fastest fix; deploying the file
creates them all up front.

---

# 8. Avatars removed: no profile pictures on the free plan

Firebase Cloud Storage cannot be enabled on the **Spark (free)** plan — it now
requires **Blaze**, even though a free tier exists inside it. Upgrading to Blaze
for avatars alone is not worth it, and every alternative (Supabase Storage,
Cloudinary, imgbb, base64 in Firestore, self-hosting) reintroduces either a
third-party dependency or the complexity this app deliberately walked away from.

So the app launches **without profile pictures**. Users are represented by a
display name in Firestore plus initials drawn in Flutter. No image is ever
uploaded, downloaded or stored.

| Concern | Before | Now |
|---|---|---|
| Avatar rendering | `Image.network` on a Storage download URL | Initials on a colour hashed from the uid — `UserAvatar`, `lib/widgets/brand_kit.dart` |
| Avatar storage | Cloud Storage `avatars/{uid}/…` | **None** |
| Upload path | `NotificationService.uploadAvatar` | Deleted — `NotificationService` has no avatar method |

## Removed

- **`firebase_storage`** from `pubspec.yaml`, and the import and `_storage`
  field in `lib/services/notification_service.dart`
- `uploadAvatar()` and its `_contentTypeFor()` helper
- **`storage.rules`**, and the `"storage"` block in `firebase.json` — the
  `firebase deploy --only … ,storage:rules` step is gone with it
- The Cloud Storage probe in `scripts/check-backend.mjs`. It is not merely
  redundant: the bucket is now *expected* to be missing, so probing it would
  print a permanent `[FAIL]` and exit non-zero, making a healthy backend look
  broken.

## Kept, deliberately

- **`photoUrl`** on `AppUser`, `Participant` and `CircleMember`, and the
  `Image.network` branch in `UserAvatar`. It is never written by Date Dawn — it
  only ever carries a picture the **sign-in provider** supplied, i.e. a Google
  account picture. That costs nothing and needs no bucket, so a Google user
  still sees their real face where the provider gave us one. Everyone else gets
  the initials tile, which is also the fallback whenever that URL fails to load.
- The `UserAvatar` call sites, now also passed a `seed` (the account's id or
  uid) so the colour is stable per person across every screen and device.

## What an avatar is now

`UserAvatar` is a `ClipOval` around a flat tinted tile with the initials on top.
The tint comes from a 31-multiplier hash of the seed modulo an eight-colour
muted palette, blended at 22% over the surface so it stays behind the content
rather than competing with the countdown. It works offline, costs nothing, and
cannot render a broken-image box.

## Verification

| Check | Result |
|---|---|
| `flutter analyze` | No issues found |
| `flutter test` | passing |
| `flutter build web` | `√ Built build\web` |

## Reversing this

If the project moves to Blaze, or a genuinely free, no-self-hosting image host is
adopted: restore `firebase_storage` in `pubspec.yaml`, re-add the `"storage"`
block to `firebase.json` and a `storage.rules`, put `uploadAvatar()` back on
`NotificationService`, and call it from Settings. Nothing else changed shape —
`photoUrl` and the `Image.network` branch were never removed, so the UI needs no
edit.

---

# 9. Two bugs found in the live app

## 9.1 `permission-denied` on Accepting a circle invitation

**Symptom.** Tapping Accept on a circle invitation failed with
`[cloud_firestore/permission-denied] Missing or insufficient permissions.`

**Cause.** `acceptCircleInvitation()` commits one batch with three writes:

1. the membership row at `circles/{id}/members/{uid}`
2. `memberIds: arrayUnion([uid])` on the circle document
3. the invitation flipped to `accepted`

The circle `update` rule verified the new member with
`exists(/circles/{id}/members/{uid})`. A plain `exists()` resolves against the
database **as it was when the request started**, so it cannot see a sibling write
from the same batch — it returned `false` for the very row the batch was adding.
The rule was therefore unsatisfiable on the only path that ever adds a member
this way, and Firestore rejected the whole batch: the circle document was left
untouched and the membership row was never written.

**Fix.** `firestore.rules` now uses `existsAfter()`, which resolves a document as
of the **end** of the batch, via a named `memberRowWritten(circleId)` helper. The
`memberIds` diff is still computed against `resource.data`, so the protection
against a non-owner granting themselves access is unchanged — the new condition
only adds the proof that the member row really is being created.

**This needs a deploy to take effect:**

```bash
firebase deploy --only firestore:rules
```

The app can be rebuilt all day; until the rules are deployed the Accept button
will keep failing.

## 9.2 A countdown shared with a circle never invited anyone

**Symptom.** Sharing a countdown with a non-couple circle made it visible to the
group, but no member received an invitation and none had a `participants` row to
accept — the invitations inbox stayed empty.

**Cause.** `createEvent()` wrote a synthetic `participants/circle:{id}` row for
the circle and stopped there. Nothing ever wrote an `invitations` document or a
per-member pending `participants` row. The comment said members "still receive an
ordinary invitation", but no code did it.

**Fix.** `createEvent()` takes `invitationRecipients` and `invitedUserIds` and
writes, in the same batch as the event:

- a pending `participants/{uid}` row per invitee, and
- an `invitations/{id}` document addressed to their email — which is what the
  invitee's inbox actually streams, since `invitationsProvider` queries
  `inviteeEmail`.

Both are batched deliberately: the `participants` and `invitations` create rules
resolve the event with `getAfter()`, so they can see the event document the same
batch is writing.

A new `circleInvitees()` helper hydrates each selected circle's `members`
subcollection — `circlesProvider` streams circle documents *without* it, so the
in-memory `circle.members` is usually empty and iterating it would have invited
nobody. `InvitationRecipient` (in `lib/core/models.dart`) carries the email
alongside the uid, because a uid alone cannot address an invitation.

## 9.3 Raw Firebase errors shown to the user

`event_editor_screen.dart` caught every non-`DataFailure` error with
`'Could not save: $e'`, which surfaced `[cloud_firestore/permission-denied]
Missing or insufficient permissions.` verbatim. `_saveError()` now maps the two
failures that actually occur — a refused write and a dead connection — to plain
sentences, and names the deploy command for the first.

---

# 10. `permission-denied` creating a countdown — the actual cause

**Symptom.** "Create countdown" on a title with no circles selected failed with
"Firestore refused the save."

**Cause.** `isAdmin()` is defined with a plain `get()`:

```
function isAdmin(eventId) {
  return signedIn() && isParticipant(eventId) && participantRole(eventId) == 'admin';
}
```

A plain `get()` resolves against the database **as it was when the request
started**, so it cannot see a document written by the *same batch*. Creating a
countdown writes the event and the creator's `participants/{uid}` admin row in
one batch, and — as of § 9.2 — that same batch also wrote `invitations`
documents, whose create rule ends with `&& isAdmin(eventId)`.

`isAdmin()` therefore returned `false` for every invitation in that batch, the
invitations rule refused, and because a Firestore batch is atomic **the entire
create was rejected** — including the event document. The countdown never
existed, which is why this looked like "I don't have rights to add anything".

This is the same `get()`-vs-`getAfter()` trap as § 9.1, one layer deeper. § 9.1
fixed the membership row; this fixes the admin lookup that gates invitations.

**Fix, two parts.**

1. **`firestore.rules`** — the `invitations` create rule now uses
   `isAdminAfter(eventId)` (new helper: `existsAfter` + `getAfter` on the
   participant row) with a fallback to
   `getAfter(.../events/{id}).data.createdBy == uid()`. Both resolve as of the
   end of the batch, so the just-written event and admin row are visible.

2. **`event_repository.dart`** — invitations no longer ride in the create batch
   at all. `createEvent()` commits the event and the creator's rows first, then
   calls `_inviteAll()` best-effort, one person at a time.

   The second part matters more than the first. A create batch is atomic, so any
   rules problem with a follow-up write destroys the thing the person actually
   asked for. Splitting them means the countdown is created and saved even if
   every invitation is refused — it degrades to "created, but nobody was told",
   which is recoverable from the countdown screen, instead of a blank failure.

   By the time `_inviteAll()` runs, the event and admin row are committed, so
   the plain `isAdmin()` in the rule is satisfied on its own; the `getAfter()`
   change is what covers the batched path if anything ever batches again.

**Still requires a deploy:**

```bash
firebase deploy --only firestore:rules
```

Verified with `firebase deploy --only firestore:rules --dry-run --project datedawn`
→ `rules file firestore.rules compiled successfully` (two pre-existing warnings:
unused `isSharedWithMyCircle`, unused `eventId` parameter in `isOwner`).

---

# 11. Invitation states, the repeated-request loop, support and build size

## 11.1 Declining left the person looking like they had not answered

`rejectInvitation()` only flipped the `invitations` document. The
`participants/{uid}` row stayed `pending` forever, so someone who had clearly
declined kept appearing in the countdown as *"Viewer · pending"* — identical to
a person who had never opened the invitation.

**Fixed:** the participant row and the invitation now move together in one
batch, and the row is written as `declined`.

## 11.2 The repeated-request loop on Accept

Three separate causes, all of which had to be fixed for it to stay fixed:

1. **No key on the invite cards.** `InvitationsInbox` emits circle cards and
   event cards from two loops into one `Column`. Without a key Flutter matches
   them to element slots *by position*, so the moment a circle invitation was
   answered and that list changed length, every event card was rebuilt as a
   new widget — discarding its `_busy` flag mid-flight. Stable
   `ValueKey('event-${id}')` / `ValueKey('circle-${id}')` keys fix the identity.

2. **No re-entry lock.** `_busy` is visual state; it gets reset by a rebuild.
   Each card now also has a plain `_submitted` bool that is *never* cleared
   once set — the actual guard against a second write while the first is in
   flight.

3. **No guard in the data layer.** `_guardInvitation()` now throws
   `DataFailure('That invitation has already been answered.')` for anything not
   `pending`, so no caller can start the loop however the UI is wired.

`InviteStatus.isAwaitingAnswer` / `isSettled` exist so the UI asks the question
in one place instead of comparing statuses ad hoc.

## 11.3 Status colours

`InviteStatusChip` renders Accepted (green), Declined (red), Waiting (amber),
Reopened (amber) and Removed (grey). Backed by new `success` and `warning`
tokens in `AppPalette` — these are the only status colours in the app, so
"accepted" is the same green everywhere.

## 11.4 Changing an answer later

`InviteStatus` gained **`declined`** and **`reopened`**, distinct from the
existing **`rejected`**:

| Status | Meaning |
|---|---|
| `pending` | invited, not answered |
| `accepted` | said yes |
| `declined` | said **no** — kept on the list so the owner can see who declined and ask again |
| `rejected` | row cancelled / invitation cancelled — never engaged |
| `reopened` | declined, then put back in front of the invitee to answer again |

`reopenInvitation()` writes `reopened` on the participant row and issues a fresh
`pending` invitation. The participant `update` rule now admits
`pending|reopened -> accepted|declined` for the invitee themselves, and nothing
else. An admin **cannot** write `accepted` on someone's behalf — the whole point
of `reopened` is that the invitee answers for themselves.

The declined row in the participants list shows a refresh button ("Invite
again") instead of the remove button.

## 11.5 "Remove" did not remove

The participants list had an `IconButton` tooltipped **Remove** that called
`updateParticipantRole(... role: viewer)` — it downgraded the role and left the
person on the countdown. It now calls a real `removeParticipant()`, which
deletes the row, behind a confirmation dialog.

## 11.6 Support page

`lib/screens/support_screen.dart`, at `/support`, with
**vhomenko119@gmail.com** as the contact. Both stores require a reachable
support contact for a published app, and the screen is written so a reviewer
following the trail lands somewhere real:

- Reaches **signed out** — the router's redirect explicitly exempts it, because
  someone who cannot get into their account is exactly who needs support.
- Copy-to-clipboard always works, then *offers* to open the mail client. A
  `mailto:` silently does nothing on desktop web with no handler registered, so
  copy-first means the address is in hand either way.
- Five real FAQs covering the things that actually go wrong (Google vs password
  accounts, circle invitations needing acceptance, changing a declined answer,
  account deletion, no ads or data selling).
- Privacy / terms links, plus `url_launcher` with a clipboard fallback so a
  failed link is never a dead tap.

Linked from Settings as "Help & support".

**Still to do by hand:** the privacy and terms URLs point at
`https://datedawn.app/privacy` and `/terms`. Those pages must exist before
submission — a store reviewer will open them.

## 11.7 Build size: 38.6 MB → 11.7 MB

`flutter build web` stages **every renderer** it might pick at runtime plus the
`.symbols` maps only a debugger wants. Measured on this project:

| | Before | After |
|---|---|---|
| `.wasm` | 30.5 MB (4 renderers) | 7.3 MB (canvaskit only) |
| `.symbols` | 7.3 MB | 0 |
| **Total** | **38.6 MB** | **11.7 MB** |

- `web/index.html` pins `renderer: 'canvaskit'` in `flutterConfiguration`, so
  the app can only ever load one renderer.
- `scripts/prune-web-build.mjs` then deletes the rest: `skwasm`, `skwasm_heavy`,
  `wimp` (WebGPU), every `*.symbols`, and the `chromium/` + `webparagraph/`
  shims. It **refuses to delete anything** if `canvaskit.wasm`/`canvaskit.js`
  are not where it expects them, so a layout change ships a big build rather
  than a blank one.
- `scripts/build-web.mjs` runs both as one command: `npm run build:web`.
- `MaterialIcons-Regular.otf` was already 99% tree-shaken (3.5 KB) — no work
  needed there.

### Verifying the prune

`scripts/verify-web-build.mjs` (`npm run verify:web`) boots the real build in
Chromium and requires: Flutter attaches a view, the frame is painted, zero
console errors, zero failed requests.

> **A note on how this was first got wrong.** The initial version measured
> "painted" by `drawImage`-ing the CanvasKit WebGL canvas into a 2D context.
> That returns an empty buffer even when the page is clearly painted, so it
> reported `painted: false (0 colours)` for a perfectly good build — a false
> negative that would have sent someone hunting a bug that did not exist. It now
> screenshots the composited frame via Chromium and counts colours in that.
> Result: `painted: true (21 colours)`, 0 errors, 0 failed requests, PASS.

## Verifying § 11

| Check | Result |
|---|---|
| `flutter analyze` | No issues found |
| `flutter test` | **79/79 passing** (4 new `InviteStatus` tests) |
| `firestore.rules` | compiled successfully (dry run) |
| `npm run build:web` | built + pruned, 11.7 MB |
| `npm run verify:web` | PASS — painted, 0 console errors, 0 failed requests |

---

# 12. Help & support as its own route

`/support` existed but was mounted **inside the `ShellRoute`**, so it inherited
the desktop sidebar and the mobile tab bar — chrome that says "you are somewhere
in the app" on a page meant to be found by someone who cannot get into the app.
It is now a **top-level route**, rendering its own `AppBar`.

## Routes moved to their own file

`lib/core/routes.dart` now holds the path constants, re-exported from
`router.dart` as `Routes` so existing imports keep working.

This was not tidiness. `router.dart` imports every screen, so `login_screen.dart`
importing it back to reach `Routes.support` is an **import cycle** — and Dart
compiles cycles happily right up until something is read before it initialises,
which surfaces as a confusing runtime failure rather than a build error. A file
that imports nothing breaks the cycle for good.

## The redirect, made prefix-safe

The public-route check was `state.matchedLocation == Routes.support`, an exact
match. That sends `/support/` — a trailing slash, a deep link, a URL a provider
might normalise — straight to the login screen, which is the exact dead end the
exemption exists to prevent. It is now `_isPublic()`, matching `/support` and
anything beneath it.

## Back is never a dead end

`/support` is meant to be opened cold: from a store listing, a bookmark, a
message to a friend. On that first page there is nothing to pop, so Flutter's
implicit back button never appears and the visitor is stranded. The screen now
renders `DangerHoverIconButton` explicitly and falls back to the home route when
the stack is empty.

Using the app's standard back arrow also fixes an inconsistency: support was the
only screen whose back arrow did not redden on hover. That hover-red is
deliberate everywhere else — a back control is a dismissal, which is the one
place red belongs.

## Reachable from where it is needed

- **Settings → "Help & support"**
- **Login screen → "Trouble signing in? Get help"** — the one place it matters
  most. Somebody stuck at the login screen is exactly who needs support, and
  until now the only way there was to guess a URL.
- **`/support` directly, signed out.** The router's redirect exempts it.

## Verifying it

`test/routes_test.dart` pins the paths: uniqueness (two constants sharing a
value is how one route silently replaces another), absolute and clean, and
`/support` staying top-level.

`scripts/verify-routes.mjs` (`npm run verify:routes`) checks the behaviour a
unit test cannot, because the redirect runs inside GoRouter rather than in a
widget. It serves the real build and loads each path with no session:

| Path | Lands on | Expected |
|---|---|---|
| `/support` | `/support` | stays public |
| `/support/` | `/support` | stays public |
| `/` | `/login` | redirected when signed out |

All three passed with 0 console errors and 0 failed requests.

## Verification for § 12

| Check | Result |
|---|---|
| `flutter analyze` | No issues found |
| `flutter test` | **82/82 passing** (3 new route tests) |
| `dart format` | clean |
| `npm run build:web` | built + pruned, 11.7 MB |
| `npm run verify:routes` | **PASS** — 3/3 paths, 0 errors |

---

# 13. The actual infinite-invitation bug, Home routing, Support in the shell

§ 11.2 claimed the accept/decline loop was fixed. **It was not.** The guards
added there were all real improvements, but none of them could have stopped this
loop, and I should have said so rather than calling it fixed.

## 13.1 Why the loop survived three guards

Every guard lived in **widget state**:

- `bool _busy` — visual state, reset on rebuild.
- `bool _submitted` — a plain field on the card's `State`.
- `ValueKey` on the cards — fixed identity *between* siblings, but does not
  survive the parent being rebuilt.

Widget state cannot survive this case:

1. `InvitationsInbox` is mounted in **more than one place** on the home screen
   (three call sites), and every instance builds its own card for the same
   invitation. Each has its own `_submitted`.
2. Each card remounts as the Firestore streams re-emit. A remount is a **new
   State object** — `_submitted` starts at `false` again.
3. `_guardInvitation(invitation)` checked `invitation.status` on the object
   passed in — a **build-time snapshot** that reads `pending` forever, however
   many times it is re-submitted. Comparing a stale copy of the state against
   itself can never detect that the state has moved on.

So the write fired again on the next rebuild, forever.

## The fix, in two parts

**1. The claim lives in a provider, not a widget.**
`invitationSubmissionProvider` (`Notifier<Set<String>>`) holds the ids already
being written. A provider outlives every rebuild and remount and is **shared by
every mounted copy**, so the first card to claim an invitation id blocks all the
others for the life of the route.

`claim()` is **synchronous on purpose**: `runAction` is async, so any `await`
before the claim would let a second tap slip through in the same frame. A failed
write calls `release()`, so a genuine retry is still possible — a refusal changed
nothing, so the invitation is still open.

**2. The guard reads the live document.**
`_guardInvitation` is now `async` and re-reads `invitations/{id}` through
Firestore, which is the only authority on whether an answer is still open. A
stale snapshot cannot answer that question. Same treatment for the circle path,
which previously checked only `isExpired` and never the status at all.

Pinned by `test/invitation_submission_test.dart`: the claim is atomic, per-id,
survives a re-read, and a release allows a retry.

## 13.2 Supabase removed from the code, not just the config

§ 7 said Supabase was removed. It was removed from the *app* — the dependency,
the schema, the service — but **not from the source**: nine dead `fromRow`
parsers, a test file exercising only those parsers, and comments still describing
a Postgres backend as if it were live.

The parsers are gone, along with `test/event_repository_row_test.dart` (which
tested a backend that no longer exists) and every stale comment.

> A note on how. I first tried a regex source-rewriter
> (`scripts/cleanup-supabase-refs.mjs`). It removed some parsers cleanly but
> **also ate a stray closing brace and a blank line** in `models.dart` — the
> analyzer still passed, because the brace happened to be an unused one. That is
> the exact hazard of editing source with regexes. I reverted to hand edits for
> the rest, verified with a diff against a backup, and deleted the script.

## 13.3 The route that matched the wrong screen

Adding `/home/:id` introduced a bug worth recording, because it was invisible to
the check I had written.

`Routes.home` is `'/'`. Giving it a bare `:id` child made the home route match
`/anything`: GoRouter matches `/`, then `:id` swallows the next segment — so
`/support` resolved to `HomeScreen(focusedEventId: 'support')`.

The symptom was two sources of truth disagreeing: the **sidebar highlighted
Support** (it reads the URL string) while the **body painted Home** (it comes
from the matched route). `verify:routes` passed, because the URL really was
`/support`.

Fixed by making the segment explicit — `home/:id` — which cannot collide with a
sibling top-level route. `/` still works and still picks the hero automatically.

## 13.4 Support is now a normal page

Moved **inside** the `ShellRoute`, so it gets the same chrome as every other
page: the sidebar on desktop, and a route the bottom bar and Settings can reach.
§ 12 had made it a standalone top-level route, which made it the one page in the
app with different chrome — the opposite of "like other pages".

It is added to `_destinations` and therefore appears in the desktop sidebar.
The mobile bottom bar shows only the first five (`_bottomBarCount`): six labels
do not fit without truncating, and Support is reachable from Settings and the
login screen, so it is the right one to leave out of the bar everyone taps daily.

It stays **public** — the redirect exemption in `_isPublic()` is what grants
that, and it has nothing to do with where the route sits in the tree.

The back arrow is now conditional: shown only when there is a stack to pop. On
desktop the sidebar *is* the navigation, and a back arrow that pops to whatever
happened to be underneath makes a page feel like a modal.

## 13.5 Home has a real route

`/home/:id` pins a countdown as the hero. Before this, "which countdown am I
looking at" lived only in provider state, so it could not be linked, bookmarked,
shared, or restored by a refresh — reload and you got whichever countdown sorted
first.

The id is resolved **against the loaded events**, not trusted directly, so a link
to a countdown that was deleted, unshared, or never belonged to this account
degrades to the normal home rather than rendering an empty hero.

## 13.6 The route check, made able to fail

`verify-routes` originally asserted only that the URL stayed `/support` — which
it did, while the wrong screen was painting. A check that cannot fail on the bug
you have is not a check.

It now compares **screenshots by hash**. Two different screens hash differently;
the same screen hashes the same. The support frame must differ from the login
frame that the home screen collapsed into.

I also tried, and abandoned, two weaker approaches on the way — worth recording
so they are not retried:

- **Scraping the DOM for words** ("mail", "support"). Flutter paints into a
  canvas; with the accessibility bridge off there are no `flt-semantics` nodes
  and no text, so the scrape returns empty and the assertion silently passes on
  nothing. It failed on a page that was rendering perfectly.
- **Asserting the absence of home text.** Same flaw, same false pass.

The hash check is the only one of the three with real signal.

## Verification for § 13

| Check | Result |
|---|---|
| `flutter analyze` | No issues found |
| `flutter test` | **78/78 passing** (6 new claim tests) |
| `dart format` | clean (43 files, 0 changed) |
| Supabase references in `lib/` | **0** |
| `npm run build:web` | built + pruned, 11.7 MB |
| `npm run verify:web` | **PASS** — painted, 0 errors, 0 failed requests |
| `npm run verify:routes` | **PASS** — 4/4 paths, frame hashes distinguish the screens |

Frame hashes from the passing run:

```
support-signed-out         5e50b2a8084c
support-trailing-slash     5e50b2a8084c   <- same screen
root-redirects-to-login    63ed57e0dc87
home-with-id               63ed57e0dc87   <- both land on login
```

### Not verified

The loop fix is verified at the **provider and data layer** (unit tests) and the
routing is verified in a **real browser**. What I could not do is tap Accept on a
live signed-in invitation — that needs a session and a real Firestore write, and
there is no emulator here. If it still loops, the log line to look for is
`[datedawn] Could not invite …`, and the next suspect would be a **second writer**
of the same invitation rather than the UI re-submitting.

---

# 14. scripts/ audit, a broken test command, and the deploy that shipped 38 MB

## 14.1 The folder was mostly healthy — one file was not

`scripts/` held 37 files. Instead of deleting on instinct, `scripts/audit-scripts.mjs`
(`npm run audit:scripts`) walks every entry point — `package.json`, the CI
workflow, `firebase.json`, the docs, `pubspec.yaml`, and imports between scripts —
and classifies each file as referenced, pattern-discovered, or possibly dead.

**One genuinely dead file: `generate-icons.mjs`.** It was a leftover from the
template's React/Capacitor app:

| It writes to | `resources/` — **does not exist** |
| It calls | `npx @capacitor/assets` — **not installed** |
| Palette | `#6fd0b6` — not this app's `#4FD1C5` |
| Referenced by | nothing but its own usage comment |

The Flutter app's icon generator is **`generate-flutter-icons.mjs`**, which is
live: documented in the README, and all four of its output paths (`assets/icon/`,
`assets/splash/`, `web/icons/`, `web/favicon.png`) exist. Two competing
implementations of the same job for two different apps, and only one is real.
Deleted `generate-icons.mjs`.

Everything else is live: 10 `*.test.mjs` suites (found by the `npm test` glob),
`*.sh` build tooling, and the platform's `grok-pwa-*` chrome, which must not be
touched.

## 14.2 `npm test` was broken

`package.json` ran, after the Node suites:

```
node --experimental-strip-types --test src/lib/app-data/app-data.test.ts
  src/lib/app-data/readiness-schedule.test.ts src/lib/auth/gate-identity.test.ts
  src/lib/auth/sign-in-gate.test.ts src/lib/events.pure.test.ts
  src/lib/auth/origins.pure.test.ts src/lib/auth/deployed-origins.test.ts
```

**None of those seven files exist.** They belonged to the deleted React app, so
`npm test` exited 1 on a project whose tests all passed — and would have failed
CI on every run. Now:

```
"test":         "node --test 'scripts/**/*.test.mjs' && flutter test"
"test:node":    node suites only
"test:flutter": flutter test only
```

`npm test` runs **78 Flutter tests plus the Node suites, exit 0.**

## 14.3 The deploy was shipping the unpruned build

§ 11.7 pruned the web build from 38.6 MB to 11.7 MB — but only for
`npm run build:web`. **Vercel does not run that.** `vercel.json` calls
`scripts/build-vercel-web.sh` directly, and that script did a bare
`flutter build web --release`. So every production deploy shipped all four
renderers while local builds looked optimised. The optimisation existed
everywhere except where it mattered.

`build-vercel-web.sh` now runs `node scripts/prune-web-build.mjs` after the
build. Confirmed still working end to end: `build/web is now 11.7 MB`,
`verify:web` PASS.

## 14.4 What "runs on a potato" actually comes to

Measured, not guessed — the bytes a browser must fetch before the first frame:

| File | Bytes |
|---|---:|
| `main.dart.js` | 3,356,940 |
| `canvaskit/canvaskit.wasm` | 7,284,602 |
| `canvaskit/canvaskit.js` | 86,987 |
| `flutter_bootstrap.js` | 13,094 |
| `MaterialIcons-Regular.otf` | 14,592 |
| `index.html` + manifest | ~3,200 |
| **Critical path** | **10.26 MB** |

Two honest observations:

- **The icons are already 99% tree-shaken** (3.5 KB of a ~1.6 MB font). That work
  was done in an earlier pass; there is nothing left to win there.
- **The remaining weight is the renderer.** `canvaskit.wasm` is 7.3 MB and there
  is no smaller Flutter web renderer — `main.dart.js` plus one wasm binary is the
  floor for this framework. The levers that remain are (a) `--wasm`, which builds
  a leaner `skwasm` pair but is Chromium-only, and (b) serving the build
  compressed (Brotli takes the wasm to roughly a third), which is a hosting
  setting rather than a code change.

  Worth saying plainly: 10 MB is a **hard floor for a Flutter web app**, not
  something more aggressive pruning will fix. If the target is genuinely "loads
  on a potato", the bigger levers are outside this repo.

## 14.5 Verification for § 14

| Check | Result |
|---|---|
| `npm run audit:scripts` | 37 files, **0 possibly dead** |
| `npm test` | **passes, exit 0** (78 Flutter + Node suites) |
| `flutter analyze` | No issues found |
| `npm run build:web` | built + pruned, 11.7 MB |
| `npm run verify:web` | **PASS** — 0 console errors, 0 failed requests |
| `scripts/build-vercel-web.sh` | now prunes; runs on the real deploy path |

### Not verified

The Vercel deploy itself. I cannot run a Vercel build from here, so the fix to
`build-vercel-web.sh` is verified by reading `vercel.json`'s `buildCommand` and
by running the same prune step locally — not by watching a real deployment.

---

# 15. Deep clean: 4.0 GB → 20 MB

The project directory was 4 GB. **None of it was junk in the repo** — 3.73 GB was
regenerable build output that had accumulated from repeated builds, and the rest
is `node_modules` + `.dart_tool`, which are live tooling.

| Before | After | |
|---:|---:|---|
| 2.49 GB | 0 | `build/` — Gradle intermediates, APKs, Flutter web output |
| 0.83 GB | 0 | `.dart_tool/` — pub + build caches |
| 0.35 GB | 0 | `node_modules/` |
| ... | 325 MB | `node_modules/` regenerated by `npm install` |
| ... | 99 MB | `build/` regenerated by `npm run build:web` |
| 19 MB | 19 MB | `.git` — real history, untouched |
| **4.0 GB** | **~460 MB** | working tree, of which all but 19 MB is regenerable |

`android/app/build/` alone was **2.2 GB** of Gradle output from an earlier
`flutter build appbundle`.

## Why this was an allowlist, not `git clean -Xdf`

The tempting one-liner is "delete everything git ignores". On this repo that
would have been **catastrophic**. `.gitignore` also covers:

```
android/app/google-services.json            the Firebase project config
android/key.properties                      the Android signing credentials
ios/Runner/GoogleService-Info.plist         iOS Firebase config
.env.local                                  environment secrets
.neon                                       Neon project binding
```

None of those are junk and none are regenerable. A blanket ignore-clean deletes
all of them, and there is **no way back** — they are not in git, which is exactly
why they are ignored and exactly why losing them is permanent.

`scripts/deep-clean.mjs` is therefore an explicit allowlist of build artifacts,
with three independent refusals before anything is removed:

1. **Never-list** — anything matching a config or credential filename is skipped
   even if it appears in the target list.
2. **Tracked-file check** — `git ls-files` runs against each target. **Any**
   tracked file means the directory holds source, and it is skipped. Every target
   in the real run reported **0 tracked files**.
3. **Forbidden roots** — `.git`, `lib`, `test`, `assets`, `web`, `pubspec.yaml`
   and friends cannot be targeted at all.

Defaults to **dry run**. `npm run clean` reports; `npm run clean:apply` removes.

```
$ npm run clean
  WOULD  build                            99.3 MB   <- flutter build / npm run build:web
  WOULD  .dart_tool                       10.7 MB   <- pub + build caches
  WOULD  node_modules                    324.8 MB   <- npm packages
Reclaimable: 434.8 MB across 3 path(s).
Regenerate everything with:
  npm run build:web
  flutter pub get
  npm install
```

## Verified recoverable

The clean is only safe if the project still works afterwards, so it was actually
regenerated and re-tested rather than assumed:

| After `flutter pub get` + `npm install` | Result |
|---|---|
| `flutter analyze` | No issues found |
| `flutter test` | **78/78 passing** |
| `npm run test:node` | pass |
| `git check-ignore build node_modules .dart_tool` | all three ignored, **0 tracked files** |
| `android/app/google-services.json` | **present** |
| `android/key.properties` | **present** |
| `.env.local` | **present** |

## Also removed

- **`supabase/`** — an empty directory, untracked, left behind when the Supabase
  backend was removed in §7. Nothing referenced it.
- **The `supabase` git index warnings.** `git status` had been reporting missing
  skills directories; the directories exist, so this was stale index state, not
  a real absence. No action taken beyond confirming the files are there.

## Keeping it clean

`build/`, `node_modules/` and `.dart_tool/` are all correctly gitignored with
**zero tracked files**, so they can never reach the repository — they only ever
occupy local disk. `npm run clean` exists so this does not silently regrow to
4 GB again; run it before archiving or handing the project on.

---

# 16. CI: the Android bundle build, made fast

The workflow was correct but paid for the same work several times over. Five
changes, ordered by how much they cost.

## 16.1 The NDK was downloaded on every single run (~1.5 GB)

The biggest cost, and it was two bugs compounding:

- The `Cache Android SDK` step had a **constant key** (`ndk-28.2.13676358`) that
  nothing ever wrote on a miss, so `actions/cache` restored nothing and then
  saved nothing — it never became a hit.
- `sdkmanager "ndk;28.2.13676358"` ran **unconditionally**, so even a successful
  restore was immediately followed by a full reinstall.

Fixed: a key distinct per NDK version (`ndk-${runner.os}-${NDK_VERSION}`), and
the install step guarded with `if: steps.ndk-cache.outputs.cache-hit != 'true'`.
The 1.5 GB now moves only when the version actually changes.

A `Verify NDK and llvm-strip` step runs before Gradle, so a missing NDK fails in
seconds with a clear message instead of surfacing ten minutes later as the opaque
`Gradle build failed`.

## 16.2 Both jobs were building — the web build was duplicate work

`analyze-and-test` ran a full `flutter build web --release`, then
`build-android` started a **second runner** that re-checked out, re-installed
Flutter and re-ran `pub get` on the same commit.

Now three jobs, all **parallel** (`needs` references: none):

| Job | What it does |
|---|---|
| `checks` | format, analyze, test — pure Dart, no SDK, no Java, no Gradle |
| `web` | build + prune; the fastest proof the widget tree compiles |
| `android` | the release bundle |

`android` deliberately has **no `needs:`**. Chaining it behind the others
serialised a ~10-minute Gradle build behind checks that cannot affect whether it
succeeds. The wall-clock time is now the slowest job, not the sum of all three.

The `web` job also runs `prune-web-build.mjs`, so it validates the real deploy
artifact (11 MB) rather than merely proving the code compiles.

## 16.3 `--analyze-size` was doubling the Dart compile

Removed. Flutter's own help confirms why it is expensive and why it cannot
coexist with the replacement:

> `--analyze-size` … **This flag cannot be combined with `--split-debug-info`.**

It forces a **second full AOT compile in a separate build mode** purely to print
a size breakdown — for a number the `Report bundle size` step already computes
from the real artifact with `wc -c`. That is roughly double the Dart compiler
time for information already in the log. It is a diagnostic to run by hand when
investigating bloat, not a per-commit step.

Added `--split-debug-info=build/symbols`, which moves DWARF symbols out of the
binary so the AAB is smaller and packaging has less to carry. The symbols upload
as a second artifact (`android-debug-symbols`), because they are required to
symbolicate a crash from that build via `flutter symbolize` — verified the
command exists.

## 16.4 Smaller cache gaps

- `gradle.properties` added to the Gradle cache key. Flipping a build flag
  (`org.gradle.caching`, `android.nonTransitiveRClass`) changes task outputs, so
  without it a cache hit could restore outputs produced under different settings.
- `GRADLE_VERSION` and `NDK_VERSION` hoisted into `env:` so a version bump
  cannot leave one cache key stale and silently disable caching.
- `actions/setup-node` added to the web job, since it runs a Node script.

## 16.5 A check so this cannot silently regress

`scripts/check-workflow.mjs` (`npm run check:workflow`) validates the workflow
without a YAML parser or network access. It catches tabs (illegal in YAML), a
job with no `runs-on`, `needs:` pointing at a job that does not exist,
`steps.<id>.outputs` referencing an id no step defines, and an NDK cache guard
with no matching install. It also asserts the specific optimisations, so
reverting one is loud rather than silent:

```
jobs: checks, web, android
needs references: none (all parallel)
ok   --analyze-size is gone from commands
ok   --split-debug-info is used
ok   no job waits on checks for android
ok   web build runs the pruner
ok   android job is not chained (parallel)
```

> A note on building this. The first version flagged `--analyze-size` as still
> present — a **false positive**, because the flag name appears in the comment
> explaining why it was removed. The check now reads only non-comment lines.
> A cleanup report that cries wolf is one you learn to ignore.

## Verification for § 16

| Check | Result |
|---|---|
| `npm run check:workflow` | No problems found |
| `flutter test` | **78/78 passing** |
| `flutter analyze` | No issues found |
| `flutter build appbundle --help` | confirms both flags and their mutual exclusion |
| `flutter symbolize` | present, so the uploaded symbols are usable |
| Gradle wrapper | 9.3.1, matching `GRADLE_VERSION` |

### Not verified

**No Android build was run here** — this machine has no Android SDK
(`ANDROID_HOME` is unset, no NDK directory), so `bundleRelease` could not be
executed. The flag behaviour is verified against Flutter's own `--help` output
and the Gradle/config values against the files, but the end-to-end artifact is
unproven. **The first CI run is the real test.** If it fails, the `Verify NDK`
step will name a missing NDK directly instead of failing inside Gradle.

Also unmeasured: the actual wall-clock saving. The NDK change removes a
~1.5 GB download (~1–3 min), the job split removes one cold runner start
(~1–2 min), and dropping `--analyze-size` removes one full AOT pass
(~2–4 min, the largest single item). Those are estimates from the shape of the
work, not from a timed run — I have no CI history to compare against.

---

# 17. `llvm-strip not found` — the real cause was my own cache step

## The error

```
::error::llvm-strip not found under /usr/local/lib/android/sdk/ndk/28.2.13676358
Error: Process completed with exit code 1.
```

## Why it happened

The check was reporting a symptom. The NDK was **never installed at all**, and
§16 had introduced the reason.

The cache step was placed **before** the install:

```yaml
- name: Cache Android NDK
  uses: actions/cache@v4
  id: ndk-cache
  with:
    path: /usr/local/lib/android/sdk/ndk/28.2.13676358   # does not exist yet
    key: ndk-${{ runner.os }}-${{ env.NDK_VERSION }}

- name: Install NDK if not cached
  if: steps.ndk-cache.outputs.cache-hit != 'true'        # therefore skipped
```

`actions/cache@v4` saves the path **at the end of the job**. Caching a directory
that does not exist yet stores an **empty entry** — and an empty entry still
counts as a `cache-hit` on the next run. So:

1. Run 1: saved an empty entry, and the install ran (miss).
2. Run 2: `cache-hit` = true → the install was **skipped** → nothing to restore
   from an empty entry → no NDK.
3. The verification step then correctly reported that `llvm-strip` was missing,
   but had no way to know the NDK had never been installed.

My own optimisation broke the job. The lesson is exact: a cache with a restore
but no matching save is not a cache, it is a trap that reports success.

## The fix

Restore and save are now **separate, explicit** steps, which is what makes the
asymmetry visible and checkable:

```yaml
- name: Restore Android NDK
  uses: actions/cache/restore@v4        # early, before the install
  id: ndk-cache
  ...

- name: Install NDK if not cached
  if: steps.ndk-cache.outputs.cache-hit != 'true'
  ...

- name: Save Android NDK
  if: always() && steps.ndk-cache.outputs.cache-hit != 'true'
  uses: actions/cache/save@v4           # END of job, after the install
  ...
```

`if: always()` on the save so a later step failing still banks the 1.5 GB
download instead of paying for it again next run.

## Self-healing, because a hollow hit is always possible

A cache hit is not proof the directory is usable — old entries, partial saves and
manual cache evictions all produce hits with no content. The install step now
also **verifies the result and repairs it**:

```yaml
- name: Ensure NDK present (repair hollow cache hits)
  run: |
    if [ ! -d "$NDK_DIR" ]; then
      echo "::warning::NDK missing (cache hit was hollow) — installing now"
      "$SDKMANAGER" "ndk;${NDK_VERSION}"
    fi
```

So a bad cache costs a slow run, not a failed one.

## The failure message now diagnoses itself

The old check tested `test -x "$STRIP"` where `STRIP` was empty on a miss, so it
reported "not found" with no context. It now prints what is actually on disk:

```
::error::llvm-strip not found under $NDK_DIR
::error::toolchains tree:
::error::  <the first 20 directories found>
::error::this usually means the NDK install is partial
::error::Removing the cache entry and re-running will re-fetch it.
```

It also finds `llvm-strip` with `find` rather than hardcoding the host triple
(`toolchains/llvm/prebuilt/linux-x86_64/bin/`), so the check keeps working if the
runner image changes architecture.

## The validator now catches this class of bug

`npm run check:workflow` gained a rule that would have caught my mistake before
it shipped:

```
steps.ndk-cache.outputs referenced but no step defines id: ndk-cache
5 cache restore(s) but 4 save(s) — a restore without a save can never hit real content
the NDK cache save runs before the NDK is installed (stores nothing)
```

**Verified it can actually fail.** I deleted the save step, ran the check, and it
reported `1 cache restore(s) but 0 save(s)` — then restored the step and it went
green again. A validator that cannot fail on the real bug is decoration, so this
one was tested against the bug it was written for.

## Verification for § 17

| Check | Result |
|---|---|
| `npm run check:workflow` | No problems found — restores 1, saves 1, save after install |
| Validator against the broken version | **FAILS** with the right message (tested) |
| `flutter test` | **78/78 passing** |
| `flutter analyze` | No issues found |
| YAML structure | 385 lines, 3 jobs, no tabs |

### Not verified

**The NDK path is not exercised end to end here** — there is no Android SDK on
this machine, so `sdkmanager "ndk;28.2.13676358"` was never run and I have not
seen `llvm-strip` at that path with my own eyes. The layout
(`ndk/<version>/toolchains/llvm/prebuilt/<host>/bin/llvm-strip`) comes from the
NDK documentation and the `find` no longer depends on it.

**If the next run still fails**, the step now prints the real directory listing
and the toolchains tree, which will name the cause directly. The most likely
remaining possibility is that the **existing empty cache entry is still present**
— caches are immutable per key, so the poisoned `ndk-*` entry must be deleted
once under Settings → Actions → Caches, or the version bumped, and the
self-repair step will then fill it correctly. That is the one manual action worth
knowing about.
