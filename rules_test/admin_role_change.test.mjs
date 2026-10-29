// Does firestore.rules actually permit an admin to change another
// collaborator's role? Run against the emulator with the REAL rules file.
//
// This is the check that a deploy log cannot give: it evaluates the rule logic
// for the exact document paths and payloads the app writes.
import { readFileSync } from 'node:fs';
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import { doc, setDoc, updateDoc } from 'firebase/firestore';

const PROJECT_ID = 'datedawn-rules-test';
let env;

function dbFor(uid) {
  return env.authenticatedContext(uid).firestore();
}

async function seed() {
  await env.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    await setDoc(doc(db, 'events/e1'), {
      title: 'Trip',
      description: '',
      createdBy: 'owner',
      at: new Date('2030-01-01'),
      createdAt: new Date('2026-01-01'),
      updatedAt: new Date('2026-01-01'),
      sharedWithMemberIds: [],
    });
    const rows = {
      owner: 'admin',
      admin: 'admin',
      'other-admin': 'admin',
      editor: 'editor',
      viewer: 'viewer',
    };
    for (const [uid, role] of Object.entries(rows)) {
      await setDoc(doc(db, `events/e1/participants/${uid}`), {
        userId: uid,
        email: `${uid}@example.com`,
        displayName: uid,
        role,
        inviteStatus: 'accepted',
      });
    }
  });
}

const results = [];

/// Every case runs against a freshly seeded database.
///
/// Sharing one set of documents between cases was itself a bug in this test:
/// an earlier case promoted `viewer` to admin, so the later "a viewer cannot
/// change a role" ran as an admin and appeared to prove a security hole that
/// did not exist. Rules are pure functions of the data; the data has to be the
/// same for each question.
async function check(name, fn) {
  await env.clearFirestore();
  await seed();
  try {
    await fn();
    results.push(['PASS', name]);
  } catch (e) {
    results.push(['FAIL', name, e?.message?.split('\n')[0]]);
  }
}

let failures = 0;
try {
  env = await initializeTestEnvironment({
    projectId: PROJECT_ID,
    firestore: {
      rules: readFileSync('firestore.rules', 'utf8'),
      host: '127.0.0.1',
      port: 8080,
    },
  });
  await check('admin promotes a viewer to editor', async () => {
    const db = dbFor('admin');
    await assertSucceeds(
      updateDoc(doc(db, 'events/e1/participants/viewer'), { role: 'editor' }),
    );
  });

  await check('admin promotes a viewer to admin', async () => {
    const db = dbFor('admin');
    await assertSucceeds(
      updateDoc(doc(db, 'events/e1/participants/viewer'), { role: 'admin' }),
    );
  });

  await check('admin can change a second (non-creator) admin', async () => {
    const db = dbFor('admin');
    await assertSucceeds(
      updateDoc(doc(db, 'events/e1/participants/other-admin'), {
        role: 'viewer',
      }),
    );
  });

  await check('admin cannot change their own role', async () => {
    const db = dbFor('admin');
    await assertFails(
      updateDoc(doc(db, 'events/e1/participants/admin'), { role: 'viewer' }),
    );
  });

  await check('nobody can change the creator role', async () => {
    const db = dbFor('admin');
    await assertFails(
      updateDoc(doc(db, 'events/e1/participants/owner'), { role: 'viewer' }),
    );
  });

  await check('creator can demote an admin', async () => {
    const db = dbFor('owner');
    await assertSucceeds(
      updateDoc(doc(db, 'events/e1/participants/admin'), { role: 'viewer' }),
    );
  });

  await check('editor cannot change a role', async () => {
    const db = dbFor('editor');
    await assertFails(
      updateDoc(doc(db, 'events/e1/participants/viewer'), { role: 'admin' }),
    );
  });

  await check('viewer cannot change a role', async () => {
    const db = dbFor('viewer');
    await assertFails(
      updateDoc(doc(db, 'events/e1/participants/editor'), { role: 'admin' }),
    );
  });

  await check('admin cannot change role AND another field at once', async () => {
    const db = dbFor('admin');
    await assertFails(
      updateDoc(doc(db, 'events/e1/participants/editor'), {
        role: 'admin',
        email: 'hacked@example.com',
      }),
    );
  });
} catch (e) {
  console.error('SETUP ERROR', e);
  failures++;
} finally {
  for (const [status, name, msg] of results) {
    console.log(`${status}  ${name}${msg ? `  -- ${msg}` : ''}`);
    if (status === 'FAIL') failures++;
  }
  if (env) await env.cleanup();
  process.exit(failures ? 1 : 0);
}
