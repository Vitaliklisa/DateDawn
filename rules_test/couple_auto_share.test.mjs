// Verify the exact post-create couple auto-share writes against firestore.rules.
import { readFileSync } from 'node:fs';
import {
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import {
  arrayUnion,
  doc,
  serverTimestamp,
  setDoc,
  updateDoc,
} from 'firebase/firestore';

const creator = 'creator';
const partner = 'partner';
const eventId = 'couple-auto-share-event';
const circleId = 'couple-auto-share-circle';
const partnerEmail = 'partner@example.com';

const env = await initializeTestEnvironment({
  projectId: 'datedawn-couple-auto-share',
  firestore: {
    rules: readFileSync('firestore.rules', 'utf8'),
    host: '127.0.0.1',
    port: 8080,
  },
});

async function write(label, path, operation) {
  try {
    await operation();
    console.log(`PASS  ${label}: ${path}`);
  } catch (error) {
    const code = error?.code ?? 'unknown';
    console.error(`REFUSED ${label}: ${path} (${code})`);
    throw error;
  }
}

try {
  await env.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    await setDoc(doc(db, `circles/${circleId}`), {
      name: 'Us',
      ownerId: creator,
      isCouple: true,
      memberIds: [creator, partner],
    });
    await setDoc(doc(db, `users/${partner}`), {
      email: partnerEmail,
      displayName: 'Partner',
    });
  });

  const db = env.authenticatedContext(creator).firestore();
  await write('create countdown', `events/${eventId}`, () =>
    setDoc(doc(db, `events/${eventId}`), {
      title: 'Anniversary',
      description: '',
      at: new Date('2030-01-01T12:00:00Z'),
      createdBy: creator,
      createdAt: new Date(),
      updatedAt: new Date(),
      deletedAt: null,
      sharedWithCircleIds: [circleId],
      sharedWithMemberIds: [],
    }),
  );
  await write(
    'create creator participant',
    `events/${eventId}/participants/${creator}`,
    () =>
      setDoc(doc(db, `events/${eventId}/participants/${creator}`), {
        userId: creator,
        role: 'admin',
        inviteStatus: 'accepted',
      }),
  );
  await write(
    'create accepted partner participant',
    `events/${eventId}/participants/${partner}`,
    () =>
      setDoc(doc(db, `events/${eventId}/participants/${partner}`), {
        userId: partner,
        role: 'editor',
        inviteStatus: 'accepted',
        joinedAt: new Date(),
        email: partnerEmail,
      }),
  );
  await write('add partner to event visibility', `events/${eventId}`, () =>
    updateDoc(doc(db, `events/${eventId}`), {
      sharedWithMemberIds: arrayUnion(partner),
      updatedAt: serverTimestamp(),
    }),
  );

  console.log('PASS  all couple auto-share writes were authorized by rules');
} finally {
  await env.clearFirestore();
  await env.cleanup();
}
