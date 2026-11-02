// A user may block another account without managing their shared event.
// Participant cleanup remains protected by the event's participant delete rule.
import { readFileSync } from 'node:fs';
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import { deleteDoc, doc, getDoc, setDoc } from 'firebase/firestore';

const env = await initializeTestEnvironment({
  projectId: 'datedawn-block-access',
  firestore: {
    rules: readFileSync('firestore.rules', 'utf8'),
    host: '127.0.0.1',
    port: 8080,
  },
});

try {
  await env.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    await setDoc(doc(db, 'events/e1'), {
      createdBy: 'owner',
      sharedWithMemberIds: ['blocker', 'target'],
    });
    await setDoc(doc(db, 'events/e1/participants/owner'), {
      userId: 'owner',
      role: 'admin',
      inviteStatus: 'accepted',
    });
    await setDoc(doc(db, 'events/e1/participants/blocker'), {
      userId: 'blocker',
      role: 'viewer',
      inviteStatus: 'accepted',
    });
    await setDoc(doc(db, 'events/e1/participants/target'), {
      userId: 'target',
      role: 'viewer',
      inviteStatus: 'accepted',
    });
    await setDoc(doc(db, 'users/blocker'), { email: 'blocker@example.com' });
  });

  const blocker = env.authenticatedContext('blocker').firestore();
  const stranger = env.authenticatedContext('stranger').firestore();
  const blockRef = doc(blocker, 'users/blocker/blocked/target');

  await assertSucceeds(setDoc(blockRef, {
    email: 'target@example.com',
    active: true,
  }));
  await assertSucceeds(getDoc(blockRef));
  await assertFails(getDoc(doc(stranger, 'users/blocker/blocked/target')));

  // A viewer cannot delete another participant row. That refusal must not
  // roll back the block or be reported as a failed block by the client.
  await assertFails(
    deleteDoc(doc(blocker, 'events/e1/participants/target')),
  );
  console.log('PASS  non-admin can block; cleanup is denied; block stays private');
} finally {
  await env.clearFirestore();
  await env.cleanup();
}
