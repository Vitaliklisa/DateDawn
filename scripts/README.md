# scripts/ — what everything is, and what is safe to remove

Answering "why are there so many `.mjs` files, are they useful?" with evidence
rather than opinion. Generated from `node scripts/classify-scripts.mjs` plus a
manual read of each importer.

**Short answer: 38 files, 3 categories.** Four dead ones were removed; the rest
earn their place.

| Category | Count | Safe to delete? |
|---|---:|---|
| **Platform chrome** — the sandbox's own infrastructure | 14 | **No** — deleting breaks the preview harness |
| **Template leftovers** — a React/Vite/Postgres app that is not in this repo | 0 | Removed |
| **This Flutter app's own tooling** | 24 | No — each has a job |

### Removed in this pass (4 files)

| File | Why it was dead |
|---|---|
| `migrate.mjs` | Ran Postgres `migrations/*.sql`. No Postgres here — the app uses Firestore. |
| `migration-plan.mjs` | Bookkeeping for the above; its header said it is shared with `src/lib/db.ts`, which does not exist. |
| `migration-plan.test.mjs` | Tested the migration planner. |
| `verify-neon.mjs` | Probed a **Neon Postgres** database. No Neon in this project. |

Also unwired: the `db:migrate` and `db:verify` npm scripts, and two stale comments
in `sign-out-plan.mjs` and `tsconfig.json` that referenced `migration-plan.mjs`.

### Still failing, and deliberately left alone (8 tests)

`npm run test:node` reports 8 failures. **All 8 are platform tests** — the
template's `VITE_AUTH_ENABLED` wiring and OG-card generation — failing because the
React app they exercise is absent from this repo. They belong to the sandbox
harness, not to your Flutter code, so removing them is not mine to do:

- `the template ships auth off`
- `the build side resolves the template's shipped app-env`
- `the wrapped command runs with the app env applied`
- `emits og:image for a public host and prefers a custom card`

They are worth knowing about: they mean `npm test` cannot be green in this repo,
which is a real cost — a red suite trains you to ignore it.

---

## 1. Platform chrome — DO NOT DELETE (12 files)

These are not yours. They are the sandbox's harness, wired in by the environment.
`vite.config.ts` **imports** `grok-pwa-plugin.mjs` (line 10) and sets
`serverDir: "./server"` (line 177), and `preview-thumbnail.mjs` is invoked by
`SandboxInternal.CapturePreviewThumbnail` by contract.

| File | What it does |
|---|---|
| `grok-pwa-plugin.mjs` | The branding injector — the "Created with Grok" pill. Imported by `vite.config.ts`. |
| `grok-pwa-shared.mjs` | Head-injection logic + OG/share-card tags. Imported by the plugin. |
| `grok-pwa-shared.d.mts` | Types for the above. |
| `grok-pwa-plugin.test.mjs` | 40+ tests for the injector (the file you pasted). |
| `install-page.html` | The `?install=1` tutorial page. |
| `app-env-plugin.mjs` | Dev-only `/__app-env` endpoint. Used by `vite.config.ts`. |
| `with-app-env.mjs` | Wraps `vite`/`flutter` so `.grok/app-env.json` reaches the child process. |
| `preview.mjs` | Preview server control (`preview:restart`). |
| `start-dev.mjs` | Detached dev server (`dev:detached`). |
| `browser-smoke.mjs` | The sandbox's page-audit harness. |
| `browser-guard.mjs` | Security: stops a capture rendering `file:///root/.grok/auth.json` into a PNG. |
| `browser-smoke-verdict.mjs` | Verdict formatting for the above. |
| `preview-thumbnail.mjs` | The preview screenshot the harness calls. |

**`browser-guard.mjs` is a security control.** It exists because the capture
scripts run Chromium as root with a URL from `argv` — unchecked, they would
happily screenshot a credentials file into an image. Removing it would not
"clean up", it would remove a guard.

## 2. Template leftovers — REMOVED (4 files)

This repo has **no `src/`, no `index.html`, no Vite app target**. It is a Flutter
app (`pubspec.yaml`) on Firestore. These four scripts served the React/Vite/
Postgres app the template ships and that was replaced:

| File | Why it was dead |
|---|---|
| `migrate.mjs` | Runs Postgres `migrations/*.sql`. There is no Postgres; the app uses Firestore. |
| `migration-plan.mjs` | Bookkeeping for the above; its own header says it is shared with `src/lib/db.ts`, which does not exist. |
| `migration-plan.test.mjs` | Tests the migration planner. |
| `verify-neon.mjs` | Probes a **Neon Postgres** database. No Neon in this project. |

### Verified LIVE — kept despite looking like leftovers

Two files look like template cruft by name and are **not**. Both were caught by
grepping the real importers after an earlier draft of this report had them
listed as dead:

| File | Why it stays |
|---|---|
| `brand-check.mjs` | `browser-smoke.mjs` (platform chrome) imports `computeBrandWarnings`. |
| `check-auth-invariant.mjs` | `browser-smoke.mjs` imports **four** symbols from it: `authInvariantWarnings`, `buildAuthEnabled`, `compareAuthInvariant`, `probeDevAuthEnabled`. |

And their test files stay too, because they test live code:
`brand-check.test.mjs`, `check-auth-invariant.test.mjs`.

This is the whole reason this exercise is done by following imports: filenames
and comments lie. `app-env-plugin.mjs`'s own header mentions
`check-auth-invariant.mjs`, which is how the dependency surfaced.

## 3. This Flutter app's own tooling — KEEP (23 files)

| File | Job |
|---|---|
| `build-web.mjs` | One-command release web build + prune |
| `prune-web-build.mjs` | 38 MB → 11 MB by dropping unused Flutter renderers |
| `verify-web-build.mjs` | Boots the built app in Chromium, asserts it paints |
| `verify-routes.mjs` | Asserts `/support` stays public, `/` redirects |
| `check-backend.mjs` | Probes Firebase Auth + Firestore |
| `check-workflow.mjs` | Validates `ci.yml` (no YAML parser needed) |
| `check-workflow-shell.mjs` | `bash -n` on every CI `run:` block |
| `deep-clean.mjs` | Reclaims ~3.7 GB of build output, safely |
| `audit-scripts.mjs` | Finds unreferenced scripts |
| `classify-scripts.mjs` | This report |
| `generate-flutter-icons.mjs` | Generates every icon/splash from one SVG (README §: icons) |
| `build-vercel-web.sh` | The actual Vercel `buildCommand` |
| `sign-out-plan.mjs` + `.test.mjs` | Sign-out sequencing |
| `write-atomic.mjs` + `.test.mjs` | Atomic file writes |
| `brand-check.mjs` | Brand/OG warnings — imported by the platform's `browser-smoke.mjs` |

---

## Why so many are `.mjs` and not `.sh` or `.ts`

`.mjs` is **ESM JavaScript** — it runs directly under Node with no build step,
which is the point:

- **No compile step.** A `.ts` script needs `tsc` or a loader before it runs.
  These run with `node scripts/x.mjs` on a bare Node 22, including in CI before
  any dependency install.
- **Not `.sh`.** Several need real file APIs, process spawning and JSON parsing
  (`deep-clean.mjs` walks trees and calls `git ls-files`; `prune-web-build.mjs`
  computes byte totals). Bash can do this, badly.
- **Testable.** `.mjs` can `import` and be imported, so `node --test` covers it.
  Shell scripts get tested by running them and hoping.

The count is high because each one is a single-purpose tool, and the platform and
template each brought their own. The Flutter app's own set — 23 — is roughly one
tool per job it actually has: build, prune, verify, deploy, check.

## What was actioned

Only the 6 template leftovers were removed. Everything else is either this app's
tooling or the platform's harness, and both categories earn their place.
