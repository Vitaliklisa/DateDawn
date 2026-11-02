# Manual verification script for collaborator flows

This file is the fallback when the sandbox cannot complete live Firebase + browser verification. It is not a completion signal; it is the exact script the user or a developer should run on a real machine with:

- Windows 11 or macOS/Linux
- Firebase CLI installed
- Chrome and Firefox installed
- Java 21 for the Firebase emulator path (if using emulator tests)
- the real project `datedawn`
- the test accounts:
  - Firefox: `alexfriedman999@gmail.com` (display name `Alex Friedman`)
  - Chrome: `vhomenko119@gmail.com`

Note: repo evidence in the app/tests points to `alexfriedman999@gmail.com`; the earlier `lex999@gmail.com` and `friedmanalex999@gmail.com` variants do not match the codebase and should be treated as wrong unless the live project uses a different alias.

## 1) Prereqs

Run these from the repo root:

```bash
firebase login:list
# If not logged in:
firebase login --no-localhost
```

If the login flow opens a device code URL, complete it in the browser.

## 2) Run the app

```bash
flutter pub get
flutter run -d chrome --web-port=5555
```

Wait for the Flutter prompt that says the app is running before opening the browser.

## 3) DevTools filters

Open Chrome DevTools on the app, then apply these filters:

- `firestore.googleapis.com`
- `googleapis.com`
- `identitytoolkit`
- `firestore`

Open Network and Console together. Keep both browsers open side by side with the two test accounts.

## 4) Required flows to reproduce

### A. Block collaborator

1. In Chrome, open an event with the Firefox collaborator on it.
2. Open the collaborator row menu.
3. Choose `Block`.
4. Observe:
   - expected: success toast / Undo appears only after the block write resolves
   - actual: if the block write fails, the toast is not a success; if it shows before the write settles, that is a bug
5. Open Settings -> Blocked people.
6. If the screen hangs, check whether the list never resolves or whether it falls to explicit error + Retry.
7. Unblock from the list.
8. Confirm the row disappears without a manual refresh.

Look for:

- console error text
- Firestore request URL and method
- HTTP status
- `error.status`
- `error.message`
- path under `users/{uid}/blocked/{blockedId}`

### B. Change role

1. In Chrome, open the event editor.
2. Find a collaborator row.
3. Open the three-dot menu.
4. Select `Change role`.
5. Choose `Editor`.
6. Expected: the row updates to Editor and persists after refresh.
7. In Firefox, confirm the new role changes the permissions actually visible to that user (for example, editor no longer sees management actions).
8. Attempt these refusals and confirm each fails with a readable message:
   - change your own role
   - escalate someone above your own role
   - change the creator's role
   - viewer/editor tries any role change

### C. Remove collaborator

1. From the same collaborator row menu, choose `Remove`.
2. Confirm the dialog and result.
3. Expected: the row disappears and the removed Firefox user immediately loses access.
4. Attempt these refusals:
   - remove the creator
   - non-manager tries to remove someone
   - manager tries to remove someone above their rank
   - self-remove (if this is a separate leave flow, say so explicitly)

### D. Invitation accept

1. In Chrome, invite the Firefox account to an event with a chosen role.
2. In Firefox, accept the invite.
3. Inspect the exact failure:
   - invite doc readable by invitee?
   - participant create attempted?
   - accept writes role plus extra fields?
   - invitee can clear or mark the invitation after accepting?
4. Also try:
   - tampered role in the request
   - accept without an invitation
   - accept twice (must be idempotent, not hang)
   - expired or revoked invite

### E. Blocked people screen error handling

1. Force a read failure by turning off the network in DevTools or by temporarily changing the rules, then reload the blocked-people screen.
2. Expected: error + Retry, not permanent spinner and not empty list.
3. Confirm the watchdog converts silence into a visible error.

## 5) What to paste back after running

Use this short form for each failed request:

```text
HTTP status: <status>
Method: <method>
URL: <url>
Firestore path: <path>
error.status: <status>
error.message: <message>
```

## 6) Verification matrix

Fill only what you can prove. Use exact values: `PASS`, `FAIL`, or `UNVERIFIED — requires user run`.

| # | Flow | Result | Evidence |
|---|---|---|---|
| 1 | Block collaborator | UNVERIFIED — requires user run | Run steps in Section 4A and paste the Firestore request/console output |
| 2 | Blocked people loads | UNVERIFIED — requires user run | Open Settings -> Blocked people and paste the screen state + console |
| 3 | Unblock | UNVERIFIED — requires user run | Confirm row disappears without refresh |
| 4 | Change role -> Editor | UNVERIFIED — requires user run | Perform change role flow and paste the response |
| 5 | Editor permissions actually change | UNVERIFIED — requires user run | Verify from Firefox session |
| 6 | Self role change refused | UNVERIFIED — requires user run | Paste the error toast / console |
| 7 | Remove collaborator | UNVERIFIED — requires user run | Confirm menu item + result |
| 8 | Removed user loses access | UNVERIFIED — requires user run | Verify in Firefox after removal |
| 9 | Remove creator refused | UNVERIFIED — requires user run | Paste the exact failure |
| 10 | Invite -> accept | UNVERIFIED — requires user run | Paste the invitation and accept failure |
| 11 | Tampered role refused | UNVERIFIED — requires user run | Paste the exact rejection |
| 12 | Accept twice -> already member | UNVERIFIED — requires user run | Paste the actual UI or console |
| 13 | Blocked screen forced error -> Retry | UNVERIFIED — requires user run | Force network failure and paste the screen state |

## 7) Minimal live rule checks

If using the emulator path instead of a live project, run:

```bash
java -version
# If Java < 21, install Java 21 first.
# Then:
firebase emulators:start --only firestore --project datedawn-rules-test
node rules_test/accept_invitation.test.mjs
node rules_test/admin_role_change.test.mjs
```

If using a throwaway Firebase project, create it and deploy the working-tree rules before running the tests:

```bash
firebase projects:create datedawn-verify-$(date +%s) --display-name "DateDawn verify"
firebase use <project-id>
firebase deploy --only firestore:rules --project <project-id>
node rules_test/accept_invitation.test.mjs
node rules_test/admin_role_change.test.mjs
firebase projects:delete <project-id> --quiet
```

## 8) Previous claim corrected

- Block: previous claim `logic present` → actual finding must be `block write races the profile create and/or the participant delete aborts on a non-admin path; confirm from the real console and Firestore request`.
- Blocked people: previous claim `screen is loaded` → actual finding must be `silent empty or permanent spinner without an explicit error + Retry` unless the live run proves otherwise.
- Change role: previous claim `menu item exists` → actual finding must be `write and UI wiring plus live permissions check; verify the actual request payload and resulting doc state`.
- Remove collaborator: previous claim `remove exists` → actual finding must be `UI placement and repo call path must be proven from the live app; if the menu lacks the action, it fails at the UI layer`.
- Invite accept: previous claim `accept logic exists` → actual finding must be `participant create/update semantics and invite readability must be proven from the live Firestore rule behavior and the actual request payload`.

This file is the fallback script. It is not the final verification state. The final state remains open until the user or developer runs it and pastes back the console output.
