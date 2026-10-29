// Isolate which create branch throws. Each run uses a trimmed rules file where
// the create rule keeps only ONE branch.
import { readFileSync } from 'node:fs';
import { initializeTestEnvironment } from '@firebase/rules-unit-testing';
import { doc, setDoc } from 'firebase/firestore';

const env = await initializeTestEnvironment({
  projectId: 'datedawn-branch',
  firestore: {
    rules: readFileSync(process.env.RULES_FILE, 'utf8'),
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
  await setDoc(doc(db, 'events/e1/participants/invitee'), {
    userId: 'invitee',
    email: 'invitee@example.com',
    role: 'editor',
    inviteStatus: 'accepted',
    invitationId: 'inv1',
    invitationEmail: 'invitee@example.com',
  });
  console.log('RESULT: WROTE');
} catch (e) {
  console.log('RESULT: DENIED', e?.code);
}

await env.clearFirestore();
await env.cleanup();
