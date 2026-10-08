// Works out which scripts/ files this app actually needs, by following real
// imports rather than guessing from filenames.
//
//   node scripts/classify-scripts.mjs
//
// The project carries two generations of tooling:
//
//   1. The sandbox template's React/Vite/Postgres stack (with-app-env, migrate,
//      preview, the grok-pwa platform chrome, and their tests).
//   2. This Flutter app's own scripts (web build, pruning, verification).
//
// Deleting the wrong half breaks the preview or the deploy, so this resolves the
// dependency graph from the entry points that actually exist — vite.config.ts,
// package.json, vercel.json, the CI workflow — and reports what is reachable.

import { readFileSync, readdirSync, existsSync } from 'node:fs';
import { join } from 'node:path';

const SCRIPTS = 'scripts';

/// Files that are PLATFORM CHROME and must never be removed, per the sandbox
/// contract: the branding injector and its wiring.
const PLATFORM_PINNED = new Set([
  'grok-pwa-plugin.mjs',
  'grok-pwa-shared.mjs',
  'grok-pwa-shared.d.mts',
  'install-page.html',
]);

/// Entry points that can legitimately pull a script in.
const ENTRY_FILES = [
  'vite.config.ts',
  'package.json',
  'vercel.json',
  'firebase.json',
  '.github/workflows/ci.yml',
];

function readIfPresent(path) {
  return existsSync(path) ? readFileSync(path, 'utf8') : '';
}

// Collect every filename mentioned anywhere in the entry points, plus imports
// between scripts, resolved transitively.
const entryText = ENTRY_FILES.map(readIfPresent).join('\n');

const all = readdirSync(SCRIPTS).filter((f) => !f.startsWith('.'));

// Seed with anything the entry points name.
const reachable = new Set();
for (const file of all) {
  const bare = file.replace(/\.(mjs|mts|html|sh)$/, '');
  if (entryText.includes(file) || entryText.includes(bare)) reachable.add(file);
}
// Platform chrome is reachable by contract, whether or not a text match fired.
for (const file of PLATFORM_PINNED) {
  if (all.includes(file)) reachable.add(file);
}

// Close over imports between scripts: if A is reachable and imports B, B is too.
let changed = true;
while (changed) {
  changed = false;
  for (const file of all) {
    if (!reachable.has(file) || !/\.(mjs|mts)$/.test(file)) continue;
    const text = readIfPresent(join(SCRIPTS, file));
    for (const m of text.matchAll(/from\s+["']\.\/([^"']+)["']/g)) {
      const dep = m[1];
      const resolved = all.find((f) => f === dep || f === `${dep}.mjs`);
      if (resolved && !reachable.has(resolved)) {
        reachable.add(resolved);
        changed = true;
      }
    }
  }
}

// Test files are reachable through the `node --test` glob in package.json,
// which matches by pattern rather than by name.
const pkg = readIfPresent('package.json');
const testsAreGlobbed = /node --test\s+'?scripts\/\*\*/.test(pkg);
for (const file of all) {
  if (testsAreGlobbed && file.endsWith('.test.mjs')) reachable.add(file);
}

const needed = all.filter((f) => reachable.has(f)).sort();
const orphaned = all.filter((f) => !reachable.has(f)).sort();

console.log(`scripts/ holds ${all.length} files\n`);

console.log(`REACHABLE — named by an entry point, imported, or a test (${needed.length})`);
for (const f of needed) console.log(`  ${f}`);

console.log(`\nORPHANED — nothing names or imports these (${orphaned.length})`);
if (orphaned.length === 0) {
  console.log('  (none)');
} else {
  for (const f of orphaned) console.log(`  ${f}`);
}

// Prove the two claims this report rests on, so a stale assumption is visible.
console.log('\nASSUMPTIONS CHECKED');

const vite = readIfPresent('vite.config.ts');
const importsPwa = /scripts\/grok-pwa-plugin/.test(vite);
console.log(
  `  vite.config.ts imports the grok-pwa plugin: ${importsPwa}` +
  (importsPwa ? '  -> platform chrome is LIVE, do not delete' : ''),
);

const hasSrc = existsSync('src');
const hasIndexHtml = existsSync('index.html');
console.log(`  src/ exists: ${hasSrc}   index.html exists: ${hasIndexHtml}`);
console.log(
  `  -> the React/Vite app this template targets is ` +
  `${hasSrc || hasIndexHtml ? 'PRESENT' : 'ABSENT (its scripts are dead weight)'}`,
);

const hasPubspec = existsSync('pubspec.yaml');
console.log(`  pubspec.yaml exists: ${hasPubspec}  -> this is a Flutter app`);
