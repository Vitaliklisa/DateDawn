# Manual verification for collaborator flows

Live verification could not be completed in this environment: the Firebase
Hosting URL returned **Site Not Found** and this browser does not expose the
two signed-in profiles requested. Use the existing Firefox and Chrome sessions
from the request; do not record account identifiers or credentials here.

## Start the app and check rules

Run from the repository root in PowerShell:

```powershell
flutter pub get
flutter run -d web-server --web-hostname 0.0.0.0 --web-port 5555
```

Open the URL printed by Flutter in both browsers. Sign into Firefox with the
first account and Chrome with the second. Before live checks, run:

```powershell
flutter test
flutter analyze
dart format --output=none --set-exit-if-changed lib test
node rules_test/run.mjs rules_test/accept_invitation.test.mjs rules_test/admin_role_change.test.mjs rules_test/block_access.test.mjs
firebase deploy --only firestore:rules --project datedawn --force
```

In DevTools, filter Network requests by `firestore.googleapis.com` and
`identitytoolkit`. Keep Console visible for Firestore errors.

## Five flows

1. **Block a collaborator**
   - In Chrome, open a countdown shared with the Firefox account. In Edit →
     Collaborators, open the Firefox account's ⋮ menu, choose **Block**, then
     confirm **Block** in the sheet.
   - What you should see: the block succeeds without requiring event-admin
     rights; the success toast appears only after the write completes. Cleanup
     denied by the event rules does not turn the saved block into a failure.

2. **Open Blocked people**
   - In Chrome, open Settings → **Blocked people** after blocking.
   - What you should see: the Firefox account appears by name/email, or a real
     empty state if no one is blocked. A read failure shows its reason and
     **Try again**, never a permanent spinner or a false empty list.

3. **Change a collaborator's role**
   - In Chrome, open the shared countdown's Edit → Collaborators. Open the
     Firefox account's ⋮ menu, choose **Change role**, and choose a role the
     current manager may grant.
   - What you should see: the row displays the saved role after the write.
     The creator's row, your own row, and roles above your authority are not
     offered; non-admins have no role-management action.

4. **Remove a collaborator**
   - In Chrome, open the accepted Firefox collaborator's ⋮ menu and choose
     **Remove**. Choose **Keep** once to verify cancellation, then repeat and
     confirm **Remove**.
   - What you should see: Keep preserves access; confirming removes the row
     only after the Firestore delete succeeds. The creator cannot be removed.

5. **Accept an invitation**
   - In Chrome, invite the Firefox account to a countdown. In Firefox, open the
     invitations inbox and choose **Accept**.
   - What you should see: the countdown appears for the invitee and the
     invitation leaves the inbox. Repeating Accept is harmless. Expired,
     withdrawn/revoked, missing, and permission-denied cases show distinct
     explanations rather than a success-shaped fallback.

Record each live result and the matching Firestore request/response in the
verification matrix. Do not mark a flow verified from the UI alone if the
corresponding write or read failed in DevTools.
