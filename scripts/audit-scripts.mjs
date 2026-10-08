// Reports which scripts in `scripts/` are actually reachable from something.
//
// The risk with "clean up the scripts folder" is deleting a file that is wired
// into CI, a git hook, or an npm script and nobody notices until a build fails.
// So instead of guessing, this walks every entry point — package.json scripts,
// the CI workflow, and any import between scripts — and classifies each file as
// referenced or not.
//
//   node scripts/audit-scripts.mjs

import { readFileSync, readdirSync } from 'node:fs';
import { join } from 'node:path';

const SCRIPTS = 'scripts';
const files = readdirSync(SCRIPTS).filter((f) => !f.startsWith('.'));

// Every place a script name can legitimately be referenced, kept SEPARATE.
//
// The first version of this merged every source into one string and then
// blanked the file's own name out of it before testing. That blanked the
// legitimate reference in `package.json` too, so every file looked orphaned —
// including `build-web.mjs`, which is wired to `npm run build:web`. A cleanup
// rule based on that output would have deleted live scripts.
//
// Each source is therefore read on its own.
const SOURCES = [
  'package.json',
  '.github/workflows/ci.yml',
  'firebase.json',
  'README.md',
  'CHECKLIST.md',
  'pubspec.yaml',
];

const texts = [];
for (const source of SOURCES) {
  try {
    texts.push({ source, text: readFileSync(source, 'utf8') });
  } catch {
    // Not present; that is fine.
  }
}

// Cross-references between scripts count too — a script invoked by another
// script is still live.
const scripts = files.filter((f) => /\.(mjs|mts|html)$/.test(f));
for (const file of scripts) {
  texts.push({
    source: `scripts/${file}`,
    text: readFileSync(join(SCRIPTS, file), 'utf8'),
  });
}

// A file's own name appearing in its own text does not count as a reference,
// so each source is checked in isolation. Two categories are live without ever
// being named:
//
//  - `*.test.mjs` — discovered by the glob in `npm test`
//    (`node --test 'scripts/**/*.test.mjs'`), so nothing names them.
//  - `*.sh` — invoked by path from `vercel.json`'s buildCommand or by hand.
//
// Reporting these as orphans on every run is how a cleanup report trains you to
// ignore it, so they are classified separately and never suggested for removal.
const isPatternDiscovered = (f) => f.endsWith('.test.mjs');
const isPathInvoked = (f) => f.endsWith('.sh') || f.endsWith('.d.mts');

const tests = [];
const pathInvoked = [];
const orphans = [];
const referenced = [];

for (const file of files) {
  const mention = texts.find(
    (t) =>
      t.source !== `scripts/${file}` &&
      (t.text.includes(file) ||
        t.text.includes(file.replace(/\.(mjs|mts|html|sh)$/, ''))),
  );

  if (mention) referenced.push({ file, via: mention.source });
  else if (isPatternDiscovered(file)) tests.push(file);
  else if (isPathInvoked(file)) pathInvoked.push(file);
  else orphans.push(file);
}

console.log(`scripts/ contains ${files.length} files\n`);

console.log(`REFERENCED (${referenced.length})`);
for (const { file, via } of referenced.sort((a, b) =>
  a.file.localeCompare(b.file),
)) {
  console.log(`  ${file.padEnd(34)} <- ${via}`);
}

console.log(`\nTEST SUITES — run by the npm test glob (${tests.length})`);
for (const f of tests.sort()) console.log(`  ${f}`);

console.log(`\nINVOKED BY PATH — vercel.json / build tooling (${pathInvoked.length})`);
for (const f of pathInvoked.sort()) console.log(`  ${f}`);

console.log(`\nPOSSIBLY DEAD (${orphans.length})`);
if (orphans.length === 0) {
  console.log('  (none)');
} else {
  for (const f of orphans.sort()) console.log(`  ${f}`);
  console.log(
    '\n  Verify each by hand before removing: `git log -1 -- scripts/<file>`\n' +
      '  and a repo-wide search. This report is a hint, not a verdict.',
  );
}
