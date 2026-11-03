import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { initializeTestEnvironment } from '@firebase/rules-unit-testing';
import {
  collection,
  collectionGroup,
  doc,
  getDoc,
  getDocs,
  query,
  setDoc,
  where,
} from 'firebase/firestore';

const creator = 'creator';
const partner = 'partner';
const eventId = 'shared-event';
const env = await initializeTestEnvironment({
  projectId: 'datedawn',
  firestore: {
    rules: readFileSync('firestore.rules', 'utf8'),
    host: '127.0.0.1',
    port: 8080,
  },
});

try {
  await env.clearFirestore();
  await env.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    await setDoc(doc(db, `events/${eventId}`), {
      title: 'Anniversary',
      description: '',
      at: new Date('2030-01-01T12:00:00Z'),
      createdBy: creator,
      createdAt: new Date(),
      updatedAt: new Date(),
      deletedAt: null,
      sharedWithMemberIds: [creator, partner],
    });
    for (const userId of [creator, partner]) {
      await setDoc(doc(db, `events/${eventId}/participants/${userId}`), {
        userId,
        role: userId === creator ? 'admin' : 'editor',
        inviteStatus: 'accepted',
      });
    }
    const seededEvent = await getDoc(doc(db, `events/${eventId}`));
    assert.deepEqual(seededEvent.data().sharedWithMemberIds, [creator, partner]);
  });

  const db = env.authenticatedContext(partner).firestore();
  const visibleEvents = await getDocs(
    query(
      collection(db, 'events'),
      where('sharedWithMemberIds', 'array-contains', partner),
    ),
  );
  assert.equal(visibleEvents.size, 1);
  assert.equal(visibleEvents.docs[0].id, eventId);
  console.log(
    'PASS  sharedWithMemberIds event query: returned shared-event (1 doc)',
  );

  try {
    await getDocs(
      query(collectionGroup(db, 'participants'), where('userId', '==', partner)),
    );
    assert.fail('participants collection-group query unexpectedly succeeded');
  } catch (error) {
    assert.equal(error.code, 'permission-denied');
    console.log(
      `EXPECTED REFUSAL  participants collection-group query: ${error.code}`,
    );
  }
} finally {
  await env.clearFirestore();
  await env.cleanup();
}
