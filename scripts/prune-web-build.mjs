// Date Dawn - prune the web build.
//
// `flutter build web` stages every renderer it might pick at runtime, plus the
// `.symbols` maps that only a debugger wants. For Date Dawn that is ~38 MB of
// files, while the app itself runs from exactly one of them.
//
// This runs after the build and deletes what the pinned renderer can never
// load. `web/index.html` pins `renderer: 'canvaskit'`, so `canvaskit.wasm` is
// the only renderer that is ever fetched.
//
//   node scripts/prune-web-build.mjs
//
// It is deliberately conservative: it only removes files it can name as
// belonging to a renderer that is not the pinned one, and it exits non-zero
// only if the renderer that IS needed has gone missing. A wrong guess here
// would produce a white screen, so the checks come first and the deletions are
// printed for review.

import { existsSync, readdirSync, rmSync, statSync } from 'node:fs';
import { join } from 'node:path';

const WEB = 'build/web';

if (!existsSync(WEB)) {
  console.error(`[prune] ${WEB} does not exist - run the web build first.`);
  process.exit(1);
}

// The one renderer the app is allowed to load, per `web/index.html`.
const KEEP = ['canvaskit.wasm', 'canvaskit.js'];

// Everything else Flutter stages. Each entry is a prefix; any file in
// `build/web` or `build/web/canvaskit` starting with it is dead weight.
const REMOVE_PREFIXES = [
  'skwasm', // WebAssembly renderer, Chromium-only, not used here
  'skwasm_heavy', // its larger sibling
  'wimp', // the WebGPU/experimental renderer
];

// `*.symbols` maps let a debugger recover names from a minified/wasm binary.
// They are a developer artifact and are never fetched by the app at runtime;
// shipping them just hands over the app's internals and bloats the upload.
const REMOVE_SUFFIXES = ['.symbols'];

const sureItIsNeeded = KEEP.filter((name) => {
  const inRoot = existsSync(join(WEB, name));
  const inCanvaskit = existsSync(join(WEB, 'canvaskit', name));
  return inRoot || inCanvaskit;
});
if (sureItIsNeeded.length === 0) {
  // Refusing here is the whole point: if the build layout changed and nothing
  // recognisable is present, deleting "the other renderers" could delete the
  // only one. Better to ship a big build than a blank one.
  console.error(
    `[prune] None of ${KEEP.join(', ')} found under ${WEB}. Refusing to ` +
    'remove anything in case the build layout has changed.',
  );
  process.exit(1);
}

let removed = 0;
let freed = 0;
const removedNames = [];

function consider(filePath, name) {
  const matches =
    REMOVE_PREFIXES.some((prefix) => name.startsWith(prefix)) ||
    REMOVE_SUFFIXES.some((suffix) => name.endsWith(suffix));
  if (!matches) return;
  // Never let a rule take out something the app actually loads.
  if (KEEP.includes(name)) return;

  try {
    const size = statSync(filePath).size;
    rmSync(filePath, { recursive: true, force: true });
    removed += 1;
    freed += size;
    removedNames.push(name);
  } catch (error) {
    console.warn(`[prune] Could not remove ${name}: ${error.message}`);
  }
}

for (const entry of readdirSync(WEB, { withFileTypes: true })) {
  consider(join(WEB, entry.name), entry.name);
}

const canvaskitDir = join(WEB, 'canvaskit');
if (existsSync(canvaskitDir)) {
  for (const entry of readdirSync(canvaskitDir, { withFileTypes: true })) {
    consider(join(canvaskitDir, entry.name), entry.name);
  }

  // `chromium/` and `webparagraph/` are per-engine shims for the renderers
  // being removed. They hold nothing the canvaskit build reads.
  for (const dir of ['chromium', 'webparagraph']) {
    const target = join(canvaskitDir, dir);
    if (!existsSync(target)) continue;
    const size = du(target);
    rmSync(target, { recursive: true, force: true });
    removed += 1;
    freed += size;
    removedNames.push(`${dir}/`);
  }
}

function du(path) {
  let total = 0;
  for (const entry of readdirSync(path, { withFileTypes: true })) {
    const full = join(path, entry.name);
    if (entry.isDirectory()) total += du(full);
    else total += statSync(full).size;
  }
  return total;
}

const mb = (bytes) => (bytes / 1048576).toFixed(1);

if (removed === 0) {
  console.log('[prune] Nothing to remove - the build looks already pruned.');
} else {
  console.log(
    `[prune] Removed ${removed} unused file(s), freeing ${mb(freed)} MB:`,
  );
  for (const name of removedNames.sort()) console.log(`  - ${name}`);
}

// Verify the renderer that is actually needed survived.
const stillThere = KEEP.some(
  (name) =>
    existsSync(join(WEB, name)) || existsSync(join(WEB, 'canvaskit', name)),
);
if (!stillThere) {
  console.error('[prune] The pinned renderer is missing. Build is not usable.');
  process.exit(1);
}

let total = 0;
for (const entry of readdirSync(WEB, { withFileTypes: true })) {
  const full = join(WEB, entry.name);
  total += entry.isDirectory() ? du(full) : statSync(full).size;
}
console.log(`[prune] build/web is now ${mb(total)} MB.`);
