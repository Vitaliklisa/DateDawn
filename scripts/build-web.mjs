// Date Dawn - the web release build, in one command.
//
//   node scripts/build-web.mjs
//
// Exists so the release build is one reproducible step rather than a sequence
// somebody has to remember. `flutter build web` stages every renderer Flutter
// might pick at runtime (~38 MB); `web/index.html` pins canvaskit, so the rest
// is downloaded by nobody. Pruning it is a 70% size cut on the deployed
// artifact, and doing it here means it cannot be forgotten.
//
// Also keeps the icon/splash generation honest: those are committed assets, so
// they only need regenerating when their config changes, not on every build.

import { spawnSync } from 'node:child_process';

function run(command, args, label) {
  console.log(`\n[build] ${label}`);
  // `shell: true` is required on Windows: `flutter` is a `.bat` wrapper there,
  // and node cannot execute a batch file directly without a shell. Every
  // argument passed here is a hard-coded literal with no spaces from user
  // input, so the injection hazard node warns about does not apply.
  const result = spawnSync(command, args, {
    stdio: 'inherit',
    shell: process.platform === 'win32',
  });
  if (result.status !== 0) {
    console.error(`[build] ${label} failed (exit ${result.status}).`);
    process.exit(result.status ?? 1);
  }
}

run('flutter', ['build', 'web', '--release'], 'flutter build web --release');
run('node', ['scripts/prune-web-build.mjs'], 'prune unused renderers');

console.log('\n[build] Done. Deploy with: firebase deploy --only hosting');
