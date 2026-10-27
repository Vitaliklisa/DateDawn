#!/usr/bin/env node
/**
 * Run a command with `.grok/app-env.json` merged into its environment.
 *
 * `dev`, `build` and `preview` all route through this wrapper, so the dev
 * server, the built bundle and the preview server can never disagree about
 * `VITE_AUTH_ENABLED` — a divergence that only shows up as a built-output
 * mismatch long after the fact. Anything that starts Vite directly bypasses it.
 *
 * Only `VITE_`-prefixed keys are honored: the file is a build flag carrier, not
 * a secret store, and only `VITE_` vars reach the browser anyway. A real
 * `process.env` entry always wins, so an explicit override still works.
 *
 * That precedence also means the file governs this workspace only. A deployed
 * build runs with the provider's project env, where the deployer sets
 * `VITE_AUTH_ENABLED` itself (today unconditionally `"true"`), so the deployed
 * flag is the platform's, not this file's.
 *
 * Vite picks the values up because `loadEnv` prefix-matches entries already in
 * `process.env`, which is why the merge has to happen before Vite starts.
 */
import { spawn } from "node:child_process";
import { existsSync, readFileSync, realpathSync } from "node:fs";
import { constants as osConstants } from "node:os";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

export const APP_ENV_REL_PATH = ".grok/app-env.json";

const VITE_PREFIX = "VITE_";

/**
 * Parse an app-env document, keeping only `VITE_`-prefixed string entries.
 * Anything unparseable is an empty environment — a workspace without the file
 * must behave exactly like today (auth on, no overrides).
 */
export function parseAppEnv(text) {
  let parsed;
  try {
    parsed = JSON.parse(text);
  } catch {
    return {};
  }
  if (parsed === null || typeof parsed !== "object" || Array.isArray(parsed)) return {};
  const env = {};
  for (const [key, value] of Object.entries(parsed)) {
    if (!key.startsWith(VITE_PREFIX)) continue;
    if (typeof value !== "string") continue;
    env[key] = value;
  }
  return env;
}

/** The app env recorded under `root`, or `{}` when the file is absent. */
export function readAppEnv(root) {
  try {
    return parseAppEnv(readFileSync(join(root, APP_ENV_REL_PATH), "utf8"));
  } catch {
    return {};
  }
}

/** File values under the process environment: an explicit override wins. */
export function mergeAppEnv(appEnv, processEnv) {
  return { ...appEnv, ...processEnv };
}

/**
 * Translate a child's `exit` `(code, signal)` into this process's exit status.
 *
 * Do not re-raise the signal with `process.kill(process.pid, signal)`: under
 * qemu-user (amd64 image builds on an arm host) a self-directed signal is
 * routinely delivered as SIGSEGV to the wrong process, which takes down the
 * test worker and fails the image build. `128 + signo` is what a shell reports
 * for a signal-killed command, so a cancelled `vite build` is still a failure.
 */
export function exitStatusFromChild(code, signal) {
  if (signal) {
    const signo = osConstants.signals[signal];
    return 128 + (typeof signo === "number" ? signo : 1);
  }
  return code ?? 1;
}

/** The workspace root (this file lives in `<root>/scripts/`). */
export function projectRoot() {
  return dirname(dirname(fileURLToPath(import.meta.url)));
}

/**
 * Whether `moduleUrl` is the script node was asked to run.
 *
 * Both sides are resolved through symlinks: node realpaths `import.meta.url`
 * but leaves `process.argv[1]` as typed, so comparing them raw makes a CLI
 * launched through a symlinked path (`/tmp` on macOS) a silent no-op.
 */
export function isMainModule(moduleUrl) {
  const entry = process.argv[1];
  if (!entry) return false;
  try {
    return realpathSync(entry) === fileURLToPath(moduleUrl);
  } catch {
    return false;
  }
}

/**
 * Read `.env.local` (created by `neon link` / `neon deploy`) into a flat map.
 *
 * Server-only vars like DATABASE_URL live here. Vite loads only VITE_-prefixed
 * values, and it does so into the CLIENT bundle — it never puts DATABASE_URL on
 * the dev server's process.env. Without this the server would keep falling back
 * to PGLite and silently ignore the linked Neon database. An explicit
 * process.env entry still wins (see mergeAppEnv), so `$env:DATABASE_URL=…` can
 * override the file for a one-off run.
 *
 * Minimal parser on purpose: KEY=value lines, optional surrounding quotes,
 * `#` comments. No variable interpolation — nothing here needs it.
 */
function readEnvLocal(root) {
  let text;
  try {
    text = readFileSync(join(root, ".env.local"), "utf8");
  } catch {
    return {};
  }
  const out = {};
  for (const line of text.split(/\r?\n/)) {
    const trimmed = line.trim();
    if (!trimmed || trimmed.startsWith("#")) continue;
    const eq = trimmed.indexOf("=");
    if (eq === -1) continue;
    const key = trimmed.slice(0, eq).trim();
    const value = trimmed.slice(eq + 1).trim().replace(/^"|"$/g, "");
    if (key) out[key] = value;
  }
  return out;
}

function resolveCommand(command) {
  if (process.platform !== "win32") return command;
  if (command.includes("\\") || command.includes("/")) return command;
  const localBin = join(projectRoot(), "node_modules", ".bin", `${command}.cmd`);
  return existsSync(localBin) ? localBin : command;
}

function main(argv) {
  const [commandRaw, ...args] = argv;
  if (!commandRaw) {
    console.error("usage: node scripts/with-app-env.mjs <command> [args…]");
    process.exit(2);
  }
  const command = resolveCommand(commandRaw);
  const env = mergeAppEnv(
    { ...readEnvLocal(projectRoot()), ...readAppEnv(projectRoot()) },
    process.env,
  );
  if (env.DATABASE_URL) {
    // One line of feedback so "am I on Neon or PGLite?" is never a guess.
    console.log("[with-app-env] DATABASE_URL set — using Postgres (Neon).");
  }

  // Publish "is direct Google sign-in configured?" to the CLIENT as a VITE_ flag.
  // GOOGLE_CLIENT_ID is server-only and must never reach the browser, so the
  // login UI cannot check it directly; this boolean is what tells it which button
  // to render. Derived here (not hand-set) so it cannot drift from the server
  // config, and an explicit VITE_GOOGLE_DIRECT still wins for a manual override.
  env.VITE_GOOGLE_DIRECT ??= env.GOOGLE_CLIENT_ID ? "true" : "false";
  if (env.VITE_GOOGLE_DIRECT === "true") {
    console.log("[with-app-env] GOOGLE_CLIENT_ID set — direct Google sign-in enabled.");
  }

  // Publish the PUBLIC Google client id for the native (Capacitor) sign-in path.
  // The plugin needs it as `initialize({ clientId })`, and it must be the WEB
  // client id even on Android (it becomes the token audience). A client id is
  // public — it ships in every web page — so it is safe in the client bundle;
  // GOOGLE_CLIENT_SECRET must NEVER be published this way.
  env.VITE_GOOGLE_WEB_CLIENT_ID ??= env.GOOGLE_CLIENT_ID ?? "";

  // Whether the native Google path is usable at all. Gated on a non-empty client
  // id so a build without Google creds falls back to the web flow instead of
  // offering a button that cannot work.
  env.VITE_NATIVE_GOOGLE ??= env.VITE_GOOGLE_WEB_CLIENT_ID ? "true" : "false";
  const child = spawn(command, args, {
    stdio: "inherit",
    env,
    shell: false,
  });
  // The dev server is long-running and is stopped by signalling this wrapper.
  for (const signal of ["SIGINT", "SIGTERM", "SIGHUP"]) {
    process.on(signal, () => child.kill(signal));
  }
  child.on("error", (err) => {
    console.error(`[with-app-env] failed to run ${command}:`, err?.message || err);
    process.exit(127);
  });
  child.on("exit", (code, signal) => {
    process.exit(exitStatusFromChild(code, signal));
  });
}

if (isMainModule(import.meta.url)) {
  main(process.argv.slice(2));
}
