// A potential invitee can disclose only whether their own uid is blocked;
// this permits a narrow pre-invite check without exposing block-list queries.
import { readFileSync } from 'node:fs';
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import { collection, doc, getDoc, getDocs, setDoc } from 'firebase/firestore';

const env = await initializeTestEnvironment({
  projectId: 'datedawn-blocked-invite',
  firestore: {
    rules: readFileSync('firestore.rules', 'utf8'),
    host: '127.0.0.1',
    port: 8080,
  },
});

try {
  await env.withSecurityRulesDisabled(async (ctx) => {
    await setDoc(doc(ctx.firestore(), 'users/blocker/blocked/invitee'), {
      email: 'blocker@example.com',
      active: true,
    });
  });

  const blocker = env.authenticatedContext('blocker').firestore();
  const invitee = env.authenticatedContext('invitee').firestore();
  const unblockedInvitee =
    env.authenticatedContext('invitee-with-no-block').firestore();
  const stranger = env.authenticatedContext('stranger').firestore();

  await assertSucceeds(
    getDocs(collection(blocker, 'users/blocker/blocked')),
  );
  await assertSucceeds(
    getDoc(doc(invitee, 'users/blocker/blocked/invitee')),
  );
  await assertSucceeds(
    getDoc(
      doc(unblockedInvitee, 'users/blocker/blocked/invitee-with-no-block'),
    ),
  );
  await assertFails(
    getDoc(doc(invitee, 'users/blocker/blocked/someone-else')),
  );
  await assertFails(
    getDocs(collection(invitee, 'users/blocker/blocked')),
  );
  await assertFails(
    getDoc(doc(stranger, 'users/blocker/blocked/invitee')),
  );
  console.log(
    'PASS  invitee can check only their own block document; list stays private',
  );
} finally {
  await env.clearFirestore();
  await env.cleanup();
}
