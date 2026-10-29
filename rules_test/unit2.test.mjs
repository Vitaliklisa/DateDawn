// Minimal unit test of the two rule primitives in question.
// Proves whether `exists(x) && get(x).data.y` throws when x is missing.
import { readFileSync } from 'node:fs';
import { initializeTestEnvironment } from '@firebase/rules-unit-testing';
import { doc, setDoc } from 'firebase/firestore';

const env = await initializeTestEnvironment({
  projectId: 'datedawn-unit',
  firestore: {
    rules: readFileSync(process.env.RULES_FILE, 'utf8'),
    host: '127.0.0.1',
    port: 8080,
  },
});

await env.withSecurityRulesDisabled(async (ctx) => {
  await setDoc(doc(ctx.firestore(), 'probe/present'), { v: 'yes' });
});

const db = env.authenticatedContext('u1').firestore();
try {
  await setDoc(doc(db, 'unsafe/r1'), { ok: true });
  console.log('RESULT: ALLOWED');
} catch (e) {
  console.log('RESULT: DENIED', e?.code);
}

await env.clearFirestore();
await env.cleanup();
