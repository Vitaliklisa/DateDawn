/**
 * Date Dawn — Firebase Auth functions.
 *
 * WHY THIS EXISTS
 * ---------------
 * Supabase picks a Postgres role from the `role` claim in the JWT it receives.
 * A Firebase ID token carries no such claim by default, so Supabase falls back
 * to `anon` — and every row-level-security policy in `supabase/schema.sql`
 * grants to `authenticated` only. The result is "permission denied" on every
 * query, even though the user is signed in.
 *
 * The fix is to stamp `role: 'authenticated'` on the token. These blocking
 * functions run during sign-up and sign-in, before the token is minted, so the
 * claim is present from the very first request.
 *
 * DEPLOY
 * ------
 *   cd firebase/functions
 *   npm install
 *   firebase deploy --only functions
 *
 * Backfill existing accounts once (they signed up before these existed):
 *
 *   cd firebase/functions
 *   GOOGLE_APPLICATION_CREDENTIALS=./service-account.json node backfill-role.js
 *
 * See `backfill-role.js` for how to get that service-account key.
 */

const functions = require('firebase-functions/v1');
const admin = require('firebase-admin');

admin.initializeApp();

/** The claim Supabase reads to choose a Postgres role. */
const AUTHENTICATED = 'authenticated';

/**
 * Runs before a new account is created and before every sign-in, so both a
 * brand-new user and an existing one always carry the claim.
 *
 * `beforeUserCreated` covers sign-up; `beforeUserSignedIn` covers every
 * subsequent sign-in, which is what repairs an account that was created before
 * these functions existed (or whose claim was somehow lost). Together they mean
 * a user never reaches Supabase without `role: authenticated`.
 */
exports.beforeCreate = functions.auth.user().beforeCreate((event) => {
  return {
    customClaims: { role: AUTHENTICATED },
  };
});

exports.beforeSignIn = functions.auth.user().beforeSignIn((event) => {
  // Only write the claim when it is missing: returning `customClaims` replaces
  // the whole object, so re-declaring it unconditionally would overwrite any
  // other claims a future feature adds.
  if (event.customClaims && event.customClaims.role === AUTHENTICATED) {
    return;
  }
  return {
    customClaims: { ...(event.customClaims ?? {}), role: AUTHENTICATED },
  };
});
