/**
 * Assert the additivity contract of the Google provider flag.
 *
 * The whole point of making direct Google *additive* is that an unconfigured
 * deploy must keep working through the broker. That is a property of the env
 * derivation in with-app-env.mjs, so it is testable without a browser: given a
 * GOOGLE_CLIENT_ID (or not), VITE_GOOGLE_DIRECT must resolve accordingly, and an
 * explicit VITE_GOOGLE_DIRECT must always win.
 */
import assert from "node:assert/strict";
import { describe, it } from "node:test";

import { readFileSync } from "node:fs";

// The derivation lives inside main(), which spawns a child process — so assert
// on the source contract rather than executing it. This keeps the test fast and
// side-effect free while still failing if someone removes the derivation.
const src = readFileSync(new URL("./with-app-env.mjs", import.meta.url), "utf8");

describe("google direct flag derivation", () => {
  it("derives VITE_GOOGLE_DIRECT from GOOGLE_CLIENT_ID", () => {
    assert.match(
      src,
      /env\.VITE_GOOGLE_DIRECT\s*\?\?=\s*env\.GOOGLE_CLIENT_ID/,
      "flag must be derived, so the UI cannot drift from the server config",
    );
  });

  it("uses the ??= form so an explicit override wins", () => {
    // `??=` (not `=`) is what lets a hand-set VITE_GOOGLE_DIRECT take precedence
    // — and, more importantly, keeps the derivation from clobbering a value a
    // deploy already ships.
    assert.ok(
      src.includes("env.VITE_GOOGLE_DIRECT ??="),
      "must use ??= so an explicit VITE_GOOGLE_DIRECT is preserved",
    );
  });

  it("loads .env.local, where GOOGLE_CLIENT_ID is expected to live", () => {
    assert.match(src, /readEnvLocal/, ".env.local must be read into the env");
  });
});
