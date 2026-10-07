// Date Dawn - backend health check.
//
// Tells you, in plain language, whether the two databases the app needs are
// actually reachable. Run it from the project root:
//
//   node scripts/check-backend.mjs
//
// It only performs READ probes with the public keys that already ship in the
// app; it never writes anything.

const FIREBASE_API_KEY = 'AIzaSyA3nS579jUK46wfNtUsYq4qFui8bBiRsws';
const FIREBASE_PROJECT = 'datedawn';
const SUPABASE_URL = 'https://wktilnzinqkelpjcwsqv.supabase.co';
const SUPABASE_KEY = 'sb_publishable_hommGM6hBArJ1GTGeqeQog_hrzpZrfQ';

const results = [];

function record(name, ok, detail) {
  results.push({ name, ok, detail });
}

async function probe(url, options = {}) {
  try {
    const response = await fetch(url, {
      ...options,
      signal: AbortSignal.timeout(20000),
    });
    const text = await response.text();
    return { status: response.status, ok: response.ok, text };
  } catch (error) {
    return { status: 0, ok: false, text: String(error?.message ?? error) };
  }
}

// --- Firebase Auth ----------------------------------------------------------
{
  const url = `https://identitytoolkit.googleapis.com/v1/projects?key=${FIREBASE_API_KEY}`;
  const { status, text } = await probe(url);
  if (status === 200) {
    record('Firebase Auth', true, 'Reachable - sign-in can work.');
  } else if (text.includes('API_KEY_INVALID')) {
    record('Firebase Auth', false, 'API key rejected - check firebase_options.dart.');
  } else {
    record('Firebase Auth', false, `HTTP ${status} - ${text.slice(0, 200)}`);
  }
}

// --- Cloud Firestore --------------------------------------------------------
// Countdowns, circles, invitations and participants all live here. If this
// fails, nothing the user creates is saved anywhere.
{
  const url =
    `https://firestore.googleapis.com/v1/projects/${FIREBASE_PROJECT}` +
    `/databases/(default)/documents/events?key=${FIREBASE_API_KEY}`;
  const { status, text } = await probe(url);
  if (status === 403 && text.includes('SERVICE_DISABLED')) {
    record(
      'Cloud Firestore',
      false,
      'DISABLED. Nothing is saved. Enable it at:\n' +
        '    https://console.firebase.google.com/project/datedawn/firestore\n' +
        '    Create database > Production mode > pick a region.',
    );
  } else if (status === 404) {
    record(
      'Cloud Firestore',
      false,
      'No database created yet. Create one at:\n' +
        '    https://console.firebase.google.com/project/datedawn/firestore',
    );
  } else if (status === 403 || status === 401) {
    // A permission error is EXPECTED for an unauthenticated read once the
    // database exists and rules are in place - it means the DB is live.
    record('Cloud Firestore', true, 'Database is live.');
  } else if (status === 200) {
    record('Cloud Firestore', true, 'Database is live.');
  } else {
    record('Cloud Firestore', false, `HTTP ${status} - ${text.slice(0, 200)}`);
  }
}

// --- Supabase: notifications inbox + theme sync -----------------------------
{
  const url = `${SUPABASE_URL}/rest/v1/notifications?select=id&limit=1`;
  const { status, text } = await probe(url, {
    headers: { apikey: SUPABASE_KEY, Authorization: `Bearer ${SUPABASE_KEY}` },
  });
  if (status === 404 && text.includes('PGRST205')) {
    record(
      'Supabase tables',
      false,
      'Project reachable, but the schema was never applied, so the inbox and\n' +
        'theme sync stay empty. Fix:\n' +
        '    Supabase dashboard > SQL Editor > paste supabase/schema.sql > Run.',
    );
  } else if (status === 200) {
    record('Supabase tables', true, 'Schema applied - the inbox can store rows.');
  } else {
    record('Supabase tables', false, `HTTP ${status} - ${text.slice(0, 200)}`);
  }
}

// --- Report -----------------------------------------------------------------
console.log('\nDate Dawn - backend health check\n' + '='.repeat(44));
let failed = 0;
for (const { name, ok, detail } of results) {
  console.log(`\n${ok ? '[OK]  ' : '[FAIL]'} ${name}`);
  console.log(`   ${detail.replace(/\n/g, '\n   ')}`);
  if (!ok) failed += 1;
}
console.log('\n' + '='.repeat(44));
if (failed === 0) {
  console.log('All backends reachable. Data will persist across reloads.');
} else {
  console.log(
    `${failed} backend(s) need attention. Until they are fixed, data created ` +
      'in the app is not saved anywhere.',
  );
}
process.exit(failed === 0 ? 0 : 1);