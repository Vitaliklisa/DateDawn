// Checks the routing contract against a real build in a real browser.
//
// The auth redirect is the thing that breaks quietly: tightening it so every
// unknown path requires sign-in also swallows `/support`, and nothing in a unit
// test notices because the redirect runs inside GoRouter, not in a widget.
//
//   node scripts/verify-routes.mjs
//
// Serves `build/web`, loads `/support` with no session, and asserts the page
// rendered and did NOT bounce to the login screen.

import { createServer } from 'node:http';
import { readFile } from 'node:fs/promises';
import { extname, join, normalize } from 'node:path';
import { chromium } from 'playwright';

const ROOT = 'build/web';
const PORT = 8098;

const TYPES = {
  '.html': 'text/html; charset=utf-8',
  '.js': 'text/javascript; charset=utf-8',
  '.mjs': 'text/javascript; charset=utf-8',
  '.wasm': 'application/wasm',
  '.json': 'application/json',
  '.css': 'text/css',
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.svg': 'image/svg+xml',
  '.ico': 'image/x-icon',
  '.ttf': 'font/ttf',
  '.otf': 'font/otf',
  '.symbols': 'application/octet-stream',
};

// A Flutter web app is a SPA: every unknown path must serve index.html so the
// client-side router can handle it. This mirrors the hosting rewrite.
const server = createServer(async (req, res) => {
  const url = decodeURIComponent((req.url ?? '/').split('?')[0]);
  const target = normalize(join(ROOT, url === '/' ? '/index.html' : url));
  if (!target.startsWith(normalize(ROOT))) {
    res.writeHead(403).end();
    return;
  }
  try {
    const body = await readFile(target);
    res.writeHead(200, {
      'Content-Type': TYPES[extname(target)] ?? 'application/octet-stream',
      'Cache-Control': 'no-store',
    });
    res.end(body);
  } catch {
    try {
      const body = await readFile(join(ROOT, 'index.html'));
      res.writeHead(200, { 'Content-Type': TYPES['.html'] });
      res.end(body);
    } catch {
      res.writeHead(404).end('not found');
    }
  }
});

await new Promise((resolve) => server.listen(PORT, '127.0.0.1', resolve));
console.log(`[routes] serving ${ROOT} on http://127.0.0.1:${PORT}`);

const browser = await chromium.launch();
const results = [];

async function check(label, path, { expectSupportPage }) {
  const page = await browser.newPage({ viewport: { width: 1280, height: 900 } });
  const consoleErrors = [];
  const failedRequests = [];
  page.on('console', (m) => m.type() === 'error' && consoleErrors.push(m.text()));
  page.on('pageerror', (e) => consoleErrors.push(String(e)));
  page.on('requestfailed', (r) =>
    failedRequests.push(`${r.url()} - ${r.failure()?.errorText}`),
  );
  page.on('response', (r) => {
    if (r.status() >= 400) failedRequests.push(`${r.status()} ${r.url()}`);
  });

  await page.goto(`http://127.0.0.1:${PORT}${path}`, {
    waitUntil: 'load',
    timeout: 60000,
  });

  // Let the router resolve and the first frame paint.
  await page.waitForTimeout(6000);

  const landedOn = new URL(page.url()).pathname;
  const text = await page.evaluate(() => document.body.innerText || '');

  await page.screenshot({
    path: `screenshots/route-${label.replace(/\W+/g, '-')}.png`,
  });
  await page.close();

  results.push({
    label,
    path,
    landedOn,
    hadErrors: consoleErrors.length + failedRequests.length,
    consoleErrors,
    failedRequests,
    textSample: text.slice(0, 120),
  });
}

// The contract: /support is public. The previous redirect sent every signed-out
// path to /login, and an exemption that is too narrow (an exact match) lets
// `/support/` slip through to the login screen.
await check('support-signed-out', '/support', { expectSupportPage: true });
await check('support-trailing-slash', '/support/', { expectSupportPage: true });
await check('root-redirects-to-login', '/', { expectSupportPage: false });

await browser.close();
server.close();

console.log('\n[routes] results');
for (const r of results) {
  console.log(
    `  ${r.label.padEnd(26)} ${r.path.padEnd(12)} -> ${r.landedOn}` +
      `  (${r.hadErrors} error(s))`,
  );
  for (const e of r.consoleErrors.slice(0, 3)) console.log(`      err  ${e}`);
  for (const e of r.failedRequests.slice(0, 3)) console.log(`      req  ${e}`);
}

// A public route must render where it was asked for, and never land on /login.
const supportOk = results
  .filter((r) => r.path.startsWith('/support'))
  .every((r) => r.landedOn === '/support' || r.landedOn === '/support/');
const rootOk = results.find((r) => r.path === '/')?.landedOn === '/login';
const noErrors = results.every((r) => r.hadErrors === 0);

console.log('\n[routes] checks');
console.log(`  /support stays public (no bounce to /login): ${supportOk}`);
console.log(`  / redirects to /login when signed out:       ${rootOk}`);
console.log(`  no console errors or failed requests:        ${noErrors}`);

const ok = supportOk && rootOk && noErrors;
console.log(`\n[routes] ${ok ? 'PASS' : 'FAIL'}`);
process.exit(ok ? 0 : 1);
