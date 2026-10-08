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
