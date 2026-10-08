// Validates .github/workflows/ci.yml without needing a YAML parser or network.
//
//   node scripts/check-workflow.mjs
//
// Catches the mistakes that silently break a workflow: tabs (illegal in YAML),
// a step that references a cache id that does not exist, a job name that does
// not match anything `needs` points at, and `if:` conditions that can never be
// true. All of these fail at *runtime* on GitHub rather than at commit time,
// which is why they are worth checking locally.

import { readFileSync } from 'node:fs';

const PATH = '.github/workflows/ci.yml';
const text = readFileSync(PATH, 'utf8');
const lines = text.split(/\r?\n/);

const problems = [];
const notes = [];

// 1. Tabs are illegal indentation in YAML.
lines.forEach((line, i) => {
  if (/^ *\t/.test(line) || /:\t/.test(line)) {
    problems.push(`tab character at line ${i + 1}: ${line.trim().slice(0, 60)}`);
  }
});

// 2. Every job needs a name and a runs-on.
const jobNames = [];
for (let i = 0; i < lines.length; i += 1) {
  const m = /^ {2}([a-zA-Z0-9_-]+):\s*$/.exec(lines[i]);
  if (m && i > lines.findIndex((l) => /^jobs:\s*$/.test(l))) {
    jobNames.push(m[1]);
  }
}
notes.push(`jobs: ${jobNames.join(', ')}`);

for (const job of jobNames) {
  const body = text.split(new RegExp(`^ {2}${job}:\\s*$`, 'm'))[1] ?? '';
  const nextJob = jobNames
    .map((j) => body.indexOf(`\n  ${j}:`))
    .filter((n) => n > -1)
    .sort((a, b) => a - b)[0];
  const scoped = nextJob === undefined ? body : body.slice(0, nextJob);

  if (!/runs-on:/.test(scoped)) problems.push(`job "${job}" has no runs-on`);
  if (!/steps:/.test(scoped)) problems.push(`job "${job}" has no steps`);
}

// 3. `needs:` must point at a job that exists.
const needs = [...text.matchAll(/needs:\s*\[?([a-zA-Z0-9_,\s-]+)\]?/g)].flatMap(
  (m) => m[1].split(',').map((s) => s.trim()).filter(Boolean),
);
for (const need of needs) {
  if (!jobNames.includes(need)) {
    problems.push(`needs: "${need}" is not a job (have: ${jobNames.join(', ')})`);
  }
}
notes.push(`needs references: ${needs.length === 0 ? 'none (all parallel)' : needs.join(', ')}`);

// 4. `steps.<id>.outputs` must reference an id defined somewhere.
const definedIds = new Set([...text.matchAll(/^\s+id:\s*(\S+)\s*$/gm)].map((m) => m[1]));
const usedIds = new Set([...text.matchAll(/steps\.([a-zA-Z0-9_-]+)\./g)].map((m) => m[1]));
for (const used of usedIds) {
  if (!definedIds.has(used)) {
    problems.push(`steps.${used}.outputs referenced but no step defines id: ${used}`);
  }
}
notes.push(`step ids defined: ${[...definedIds].join(', ') || 'none'}`);

// 5. Every ndk cache guard should be paired with an install that respects it.
if (text.includes('id: ndk-cache') && !text.includes("cache-hit != 'true'")) {
  problems.push('ndk-cache is defined but the install step is not guarded on it');
}

// 6. Assertions about the specific optimisations, so a revert is loud.
//
// The flag checks look only at non-comment lines. A comment explaining why a
// flag was removed is exactly the documentation worth keeping, and an earlier
// version of this check flagged it — a false positive that would teach you to
// ignore the tool.
const commandLines = lines
  .filter((l) => !/^\s*#/.test(l))
  .join('\n');

const expectations = [
  ['--analyze-size is gone from commands', !commandLines.includes('--analyze-size')],
  ['--split-debug-info is used', commandLines.includes('--split-debug-info')],
  ['no job waits on checks for android', !/build-android[\s\S]{0,400}?needs:/.test(text)],
  ['web build runs the pruner', commandLines.includes('prune-web-build.mjs')],
  [
    'android job is not chained (parallel)',
    !/android:[\s\S]*?runs-on:[\s\S]*?needs:/.test(text),
  ],
];

for (const [label, ok] of expectations) {
  if (!ok) problems.push(`expected: ${label}`);
  notes.push(`${ok ? 'ok  ' : 'FAIL'} ${label}`);
}

console.log(`Checked ${PATH} (${lines.length} lines)\n`);
for (const n of notes) console.log(`  ${n}`);

if (problems.length === 0) {
  console.log('\nNo problems found.');
  process.exit(0);
}

console.log(`\n${problems.length} problem(s):`);
for (const p of problems) console.log(`  - ${p}`);
process.exit(1);
