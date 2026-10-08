// Validates every `run:` shell script in the workflow with `bash -n`.
//
//   node scripts/check-workflow-shell.mjs
//
// `bash -n` parses without executing, so this catches a missing `fi`, an
// unbalanced quote, or a bad `if` before a run gets far enough to waste the
// NDK's 1.5 GB download. That is exactly the failure this guards against: a
// syntax error in the *install* step is discovered after the slow part.
//
// The scripts are extracted from the YAML by indentation rather than with a
// YAML parser, so this keeps working with no dependencies.

import { execFileSync } from 'node:child_process';
import { readFileSync, writeFileSync, mkdtempSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';

const PATH = '.github/workflows/ci.yml';
const lines = readFileSync(PATH, 'utf8').split(/\r?\n/);

// Collect each `run: |` block: the marker line, then every following line that
// is indented deeper than the marker.
const blocks = [];
for (let i = 0; i < lines.length; i += 1) {
  const m = /^(\s*)run:\s*\|/.exec(lines[i]);
  if (!m) continue;
  const indent = m[1].length;
  const body = [];
  let j = i + 1;
  for (; j < lines.length; j += 1) {
    const line = lines[j];
    if (line.trim() === '') {
      body.push('');
      continue;
    }
    const lineIndent = line.length - line.trimStart().length;
    if (lineIndent <= indent) break;
    body.push(line.slice(indent + 2));
  }
  // Name the step from the nearest preceding `- name:` for a readable report.
  let name = `run: at line ${i + 1}`;
  for (let k = i; k >= 0 && k > i - 15; k -= 1) {
    const n = /^\s*-\s*name:\s*(.+)$/.exec(lines[k]);
    if (n) {
      name = n[1].trim();
      break;
    }
  }
  blocks.push({ name, line: i + 1, body: body.join('\n') });
}

if (blocks.length === 0) {
  console.log('No `run: |` blocks found — nothing to check.');
  process.exit(0);
}

const dir = mkdtempSync(join(tmpdir(), 'ci-shell-'));
const problems = [];

// Resolve a bash. On Windows it is usually Git Bash and not on PATH, so the
// well-known install locations are probed before giving up. If none is found
// the check SKIPS rather than failing: reporting "7 with syntax errors" because
// the validator could not find its own tool is a false alarm, and a checker that
// cries wolf is one people learn to ignore.
function resolveBash() {
  const candidates = [
    'bash',
    'C:\\Program Files\\Git\\bin\\bash.exe',
    'C:\\Program Files (x86)\\Git\\bin\\bash.exe',
    `${process.env.LOCALAPPDATA}\\Programs\\Git\\bin\\bash.exe`,
  ];
  for (const candidate of candidates) {
    try {
      execFileSync(candidate, ['--version'], { stdio: 'pipe' });
      return candidate;
    } catch {
      // Try the next one.
    }
  }
  return null;
}

const bash = resolveBash();
if (!bash) {
  console.log(
    'No bash found (checked PATH and the Git install locations) — skipping.\n' +
      'This check only runs where bash is available; CI runs on ubuntu-latest.',
  );
  process.exit(0);
}
console.log(`Using: ${bash}\n`);

for (const [index, block] of blocks.entries()) {
  const file = join(dir, `step-${index}.sh`);
  writeFileSync(file, `${block.body}\n`, 'utf8');
  try {
    execFileSync(bash, ['-n', file], { stdio: 'pipe' });
    console.log(`  ok    ${block.name}  (line ${block.line})`);
  } catch (error) {
    const detail = String(error.stderr ?? error.message)
      .split('\n')
      .filter((l) => l.trim())
      .slice(0, 3)
      .join('\n          ');
    console.log(`  FAIL  ${block.name}  (line ${block.line})`);
    console.log(`          ${detail}`);
    problems.push(block.name);
  }
}

console.log(`\nChecked ${blocks.length} script(s) with bash -n.`);
if (problems.length === 0) {
  console.log('All parse cleanly.');
  process.exit(0);
}
console.log(`${problems.length} with syntax errors.`);
process.exit(1);
