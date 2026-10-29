// Which branch lets a viewer through? Test each field combination.
import { readFileSync } from 'node:fs';
import {
  assertFails,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import { doc, setDoc, updateDoc } from 'firebase/firestore';

const env = await initializeTestEnvironment({
  projectId: 'datedawn-probe',
  firestore: {
    rules: readFileSync('firestore.rules', 'utf8'),
    host: '127.0.0.1',
    port: 8080,
  },
});

async function seed() {
  await env.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    await setDoc(doc(db, 'events/e1'), {
      title: 'T',
      createdBy: 'owner',
      at: new Date('2030-01-01'),
      sharedWithMemberIds: [],
    });
    for (const [uid, role] of Object.entries({
      owner: 'admin',
      admin: 'admin',
      viewer: 'viewer',
      editor: 'editor',
    })) {
      await setDoc(doc(db, `events/e1/participants/${uid}`), {
        userId: uid,
        email: `${uid}@example.com`,
        role,
        inviteStatus: 'accepted',
      });
    }
  });
}

async function probe(label, uid, target, patch) {
  await env.clearFirestore();
  await seed();
  const db = env.authenticatedContext(uid).firestore();
  try {
    await assertFails(updateDoc(doc(db, `events/e1/participants/${target}`), patch));
    console.log(`DENIED   ${label}`);
  } catch (e) {
    console.log(`ALLOWED  ${label}  :: ${e?.message?.split('\n')[0]}`);
  }
}

await probe('viewer -> editor role', 'viewer', 'editor', { role: 'admin' });
await probe('viewer -> own row role', 'viewer', 'viewer', { role: 'admin' });
await probe('editor -> viewer role', 'editor', 'viewer', { role: 'admin' });
await probe('viewer -> owner role', 'viewer', 'owner', { role: 'viewer' });
await probe('viewer -> viewer role (same)', 'viewer', 'editor', { role: 'editor' });

await env.clearFirestore();
await env.cleanup();
