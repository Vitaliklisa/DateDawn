// Which branch of the participant create/update rules errors?
// Uses a stripped rules file per branch to isolate the throwing helper.
import { readFileSync, writeFileSync } from 'node:fs';
import { initializeTestEnvironment } from '@firebase/rules-unit-testing';
import { doc, getDoc, setDoc } from 'firebase/firestore';

const RESULTS = process.argv[2] || 'create';

const env = await initializeTestEnvironment({
  projectId: 'datedawn-bisect',
  firestore: {
    rules: readFileSync(process.env.RULES_FILE || 'firestore.rules', 'utf8'),
    host: '127.0.0.1',
    port: 8080,
  },
});

await env.withSecurityRulesDisabled(async (ctx) => {
  const db = ctx.firestore();
  await setDoc(doc(db, 'events/e1'), {
    title: 'T',
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

const db = env.authenticatedContext('invitee').firestore();
try {
  if (RESULTS === 'create') {
    await setDoc(doc(db, 'events/e1/participants/invitee'), {
      userId: 'invitee',
      email: 'invitee@example.com',
      role: 'editor',
      inviteStatus: 'accepted',
      invitationId: 'inv1',
      invitationEmail: 'invitee@example.com',
    });
  } else {
    await setDoc(doc(db, 'events/e1/participants/invitee'), {
      userId: 'invitee',
      email: 'invitee@example.com',
      role: 'editor',
      inviteStatus: 'pending',
      invitationId: 'inv1',
      invitationEmail: 'invitee@example.com',
    });
  }
  console.log('WROTE OK');
} catch (e) {
  console.log('WRITE FAILED:', e?.code, '|', e?.message?.split('\n')[0]);
}

await env.clearFirestore();
await env.cleanup();
