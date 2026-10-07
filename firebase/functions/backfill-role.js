/**
 * One-off backfill: stamp `role: 'authenticated'` on every existing account.
 *
 * WHY
 * ---
 * `beforeCreate` only runs for accounts created AFTER it was deployed, and
 * `beforeSignIn` only helps a user who signs in again. Anyone who already had
 * an account would keep getting `permission denied` from Supabase until they
 * happened to sign out and back in. This sets the claim for everyone once.
 *
 * HOW TO RUN
 * ----------
 * 1. Firebase console -> Project settings -> Service accounts ->
 *    "Generate new private key". Save the JSON as
 *    `firebase/functions/service-account.json`.
 *    NEVER commit that file — it is a full admin credential. It is already
 *    covered by the `.gitignore` in this folder.
 * 2. Then:
 *
 *      cd firebase/functions
 *      npm install
 *      node backfill-role.js
 *
 * Safe to re-run: it only writes when the claim is missing or wrong. Delete the
 * service-account file when you are done.
 */

const admin = require('firebase-admin');
const path = require('node:path');
const fs = require('node:fs');

const keyPath = path.join(__dirname, 'service-account.json');
if (!fs.existsSync(keyPath)) {
  console.error(
    'Missing firebase/functions/service-account.json.\n' +
    'Generate one: Firebase console -> Project settings -> Service accounts ->\n' +
    '"Generate new private key", then save it next to this script.',
  );
  process.exit(1);
}

admin.initializeApp({
  credential: admin.credential.cert(require(keyPath)),
});

const AUTHENTICATED = 'authenticated';

async function backfill() {
  let nextPageToken;
  let scanned = 0;
  let updated = 0;
  let skipped = 0;

  do {
    const page = await admin.auth().listUsers(1000, nextPageToken);

    for (const user of page.users) {
      scanned += 1;
      const claims = user.customClaims || {};

      if (claims.role === AUTHENTICATED) {
        skipped += 1;
        continue;
      }

      // Merge rather than replace: any other claim on the account survives.
      await admin
        .auth()
        .setCustomUserClaims(user.uid, { ...claims, role: AUTHENTICATED });
      updated += 1;
      console.log(`  set role=authenticated for ${user.uid} (${user.email ?? 'no email'})`);
    }

    nextPageToken = page.pageToken;
  } while (nextPageToken);

  console.log(
    `\nDone. Scanned ${scanned}, updated ${updated}, already correct ${skipped}.`,
  );
  console.log(
    'Users must refresh their token for the claim to take effect — the app ' +
    'forces this on every sign-in, so a simple sign-out and back in is enough.',
  );
}

backfill().catch((error) => {
  console.error('Backfill failed:', error);
  process.exit(1);
});
