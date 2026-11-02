// Runs a rules test file against the Firestore emulator with THIS project's
// rules file.
//
// `npx firebase emulators:exec` inherits nothing on this machine, and the
// emulator needs Java 21 — firebase-tools refuses to start on 17. JAVA_HOME is
// therefore set here (to the Microsoft OpenJDK 21 winget installs) rather than
// left to the invoking shell, so every run of the rules tests is one command and
// does not depend on the machine's global JDK.
//
//   node rules_test/run.mjs rules_test/accept_invitation.test.mjs [...]
//
// Exit code is the test's own.
import { spawnSync } from 'node:child_process';
import { existsSync } from 'node:fs';

const JDK21 = 'C:\\Program Files\\Microsoft\\jdk-21.0.13.21-hotspot';

const javaHome = [process.env.DATEDAWN_JAVA_HOME, JDK21].find(
  (dir) => dir && existsSync(dir + '\\bin\\java.exe'),
);
if (!javaHome) {
  console.error(
    'Java 21 not found. Install it with:\n' +
      '  winget install Microsoft.OpenJDK.21 --silent\n' +
      'or set DATEDAWN_JAVA_HOME to a JDK 21 directory.',
  );
  process.exit(2);
}

const files = process.argv.slice(2);
if (files.length === 0) {
  console.error('usage: node rules_test/run.mjs <test-file> [...]');
  process.exit(2);
}

const command = files.map((f) => `node ${f}`).join(' && ');
const projectId = `datedawn-rules-${process.pid}`;

const result = spawnSync(
  process.platform === 'win32' ? 'npx.cmd' : 'npx',
  [
    'firebase',
    'emulators:exec',
    '--only',
    'firestore',
    '--project',
    projectId,
    command,
  ],
  {
    stdio: 'inherit',
    shell: false,
    env: {
      ...process.env,
      JAVA_HOME: javaHome,
      PATH: `${javaHome}\\bin;${process.env.PATH ?? ''}`,
    },
  },
);

process.exit(result.status ?? 1);
