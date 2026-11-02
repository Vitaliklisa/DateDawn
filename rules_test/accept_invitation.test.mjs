// Accepting an invitation, against the REAL rules.
//
// This exercises the exact batch `EventRepository.acceptInvitation` writes: a
// participant row merge + the invitation status flip + the event visibility
// update. Any rule that errors turns the whole batch into "permission-denied".
import { readFileSync } from 'node:fs';
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import {
  collection,
  doc,
  setDoc,
  updateDoc,
  writeBatch,
} from 'firebase/firestore';

const env = await initializeTestEnvironment({
  projectId: 'datedawn-accept',
  firestore: {
    rules: readFileSync('firestore.rules', 'utf8'),
    host: '127.0.0.1',
    port: 8080,
  },
});

const results = [];
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

async function seed() {
  await env.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    await setDoc(doc(db, 'events/e1'), {
      title: 'Trip',
      createdBy: 'owner',
      at: new Date('2030-01-01'),
      sharedWithMemberIds: [],
    });
    await setDoc(doc(db, 'events/e1/participants/owner'), {
      userId: 'owner',
      email: 'owner@example.com',
      role: 'admin',
      inviteStatus: 'accepted',
    });
    await setDoc(doc(db, 'users/invitee'), { email: 'invitee@example.com' });
    await setDoc(doc(db, 'invitations/inv1'), {
      eventId: 'e1',
      invitedBy: 'owner',
      inviteeEmail: 'invitee@example.com',
      role: 'editor',
      status: 'pending',
      createdAt: new Date('2026-01-01'),
      expiresAt: new Date('2030-01-01'),
      eventTitle: 'Trip',
    });
  });
}

function acceptBatch(uid, invitationId, role) {
  return async () => {
    // The invitation is matched against the caller's VERIFIED token email
    // (`myEmail()`), so the test has to authenticate with one. Signing in as a
    // bare uid left the claim empty and made every accept look refused.
    const db = env
      .authenticatedContext(uid, { email: 'invitee@example.com' })
      .firestore();
    const batch = writeBatch(db);
    batch.set(
      doc(db, 'events/e1/participants/invitee'),
      {
        userId: 'invitee',
        email: 'invitee@example.com',
        role,
        inviteStatus: 'accepted',
        joinedAt: new Date(),
        invitationId,
        invitationEmail: 'invitee@example.com',
      },
      { merge: true },
    );
    batch.update(doc(db, 'invitations/inv1'), { status: 'accepted' });
    batch.update(doc(db, 'events/e1'), {
      sharedWithMemberIds: ['invitee'],
      updatedAt: new Date(),
    });
    await batch.commit();
  };
}

await check('invitee accepts a valid invitation', async () => {
  const run = acceptBatch('invitee', 'inv1', 'editor');
  await assertSucceeds(run());
});

await check('accept with the role the invitation did NOT grant is refused',
  async () => {
    const run = acceptBatch('invitee', 'inv1', 'admin');
    await assertFails(run());
  });

await check('accept without a real invitation is refused', async () => {
  const run = acceptBatch('invitee', 'does-not-exist', 'viewer');
  await assertFails(run());
});

await check('an expired invitation cannot authorize a participant row', async () => {
  await env.withSecurityRulesDisabled(async (ctx) => {
    await updateDoc(doc(ctx.firestore(), 'invitations/inv1'), {
      expiresAt: new Date('2020-01-01'),
    });
  });
  await assertFails(acceptBatch('invitee', 'inv1', 'editor')());
});

await check('a stranger cannot accept into someone else\'s event', async () => {
  const run = acceptBatch('stranger', 'inv1', 'editor');
  await assertFails(run());
});

// The invited uid may create their OWN row when there is none yet (an invite
// sent to an email address, or a pending row that was cleaned up). This is the
// narrow `isSelfAnsweringInvite()` branch, and it must not become a way to
// grant oneself a role the invitation did not name.
function selfCreateBatch(uid, role) {
  return async () => {
    const db = env.authenticatedContext(uid, {
      email: 'invitee@example.com',
    }).firestore();
    await setDoc(
      doc(db, 'events/e1/participants/invitee'),
      {
        userId: 'invitee',
        email: 'invitee@example.com',
        role,
        inviteStatus: 'accepted',
        joinedAt: new Date(),
        invitationId: 'inv1',
        invitationEmail: 'invitee@example.com',
      },
      { merge: true },
    );
    await updateDoc(doc(db, 'invitations/inv1'), { status: 'accepted' });
  };
}

await check('the invited uid creates their own row with the invited role',
  async () => {
    await assertSucceeds(selfCreateBatch('invitee', 'editor')());
  });

await check('the invited uid cannot create their own row as admin', async () => {
  await assertFails(selfCreateBatch('invitee', 'admin')());
});

await check('an invitee cannot create unrelated fields on their row', async () => {
  const db = env.authenticatedContext('invitee', {
    email: 'invitee@example.com',
  }).firestore();
  await assertFails(
    setDoc(doc(db, 'events/e1/participants/invitee'), {
      userId: 'invitee',
      email: 'invitee@example.com',
      role: 'editor',
      inviteStatus: 'accepted',
      joinedAt: new Date(),
      invitationId: 'inv1',
      invitationEmail: 'invitee@example.com',
      isAdmin: true,
    }),
  );
});

await check('an invitee cannot add unrelated fields while accepting', async () => {
  const db = env.authenticatedContext('invitee', {
    email: 'invitee@example.com',
  }).firestore();
  await env.withSecurityRulesDisabled(async (ctx) => {
    await setDoc(doc(ctx.firestore(), 'events/e1/participants/invitee'), {
      userId: 'invitee',
      email: 'invitee@example.com',
      role: 'editor',
      inviteStatus: 'pending',
      invitationId: 'inv1',
      invitationEmail: 'invitee@example.com',
    });
  });
  await assertFails(
    updateDoc(doc(db, 'events/e1/participants/invitee'), {
      inviteStatus: 'accepted',
      isAdmin: true,
    }),
  );
});

await check('a stranger cannot create a row citing my invitation', async () => {
  await assertFails(selfCreateBatch('stranger', 'editor')());
});

for (const [status, name, msg] of results) {
  console.log(`${status}  ${name}${msg ? `  -- ${msg}` : ''}`);
}
await env.clearFirestore();
await env.cleanup();
process.exit(results.some(([s]) => s === 'FAIL') ? 1 : 0);
