#!/usr/bin/env node
/**
 * Start the dev server detached, so it keeps running after this terminal
 * command returns.
 *
 *   node scripts/start-dev.mjs
 *   (or: npm run dev:detached)
 *
 * Needed on Windows because the sandbox-style "run in background" wrapper kills
 * the child when its parent command times out. This spawns Vite via its JS entry
 * (not the `vite` shim, which `spawn` can't resolve on Windows), detached and
 * with stdio pointed at a log file, then exits immediately.
 *
 * The app must listen on 0.0.0.0:8080 so your phone can reach it over Wi-Fi.
 */
import { spawn } from "node:child_process";
import { openSync } from "node:fs";
import { join } from "node:path";

const ROOT = process.cwd();
const PORT = process.env.PORT ?? "8080";

// Route through the env wrapper so a detached dev server sees the same
// environment as `npm run dev` — in particular DATABASE_URL from .env.local, so
// it uses the linked Neon database instead of falling back to PGLite.
const wrapper = join(ROOT, "scripts", "with-app-env.mjs");
// Vite's JS entry — avoids the Windows `vite` / `vite.CMD` resolution problem.
const viteBin = join(ROOT, "node_modules", "vite", "bin", "vite.js");

// An open fd, not a stream: node 24 rejects a lazy WriteStream passed to stdio.
const log = openSync(join(ROOT, "dev-server.log"), "a");

const child = spawn(
  process.execPath,
  [wrapper, process.execPath, viteBin, "dev", "--host", "0.0.0.0", "--port", PORT],
  { cwd: ROOT, detached: true, stdio: ["ignore", log, log], env: process.env },
);

child.unref();
console.log(`[start-dev] launched detached (pid ${child.pid}) on http://0.0.0.0:${PORT}`);
console.log(`[start-dev] logs -> ${join(ROOT, "dev-server.log")}`);
