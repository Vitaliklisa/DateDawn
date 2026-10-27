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

import { createHash } from 'node:crypto';
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

  // Flutter paints into a canvas. With the accessibility bridge off there are
  // no `flt-semantics` nodes and no DOM text to read, so scraping the page for
  // words returns nothing — which is what made the first version of this
  // assertion fail against a page that was rendering perfectly.
  //
  // So compare pixels instead. A hash of the composited frame is stable for a
  // given page and wildly different between two different pages. Comparing the
  // support page against the home page is a real signal that they are distinct
  // screens, where scraping for the word "mail" was not.
  const shot = await page.screenshot({
    clip: { x: 240, y: 0, width: 700, height: 300 },
  });
  const frameHash = createHash('sha1').update(shot).digest('hex').slice(0, 12);

  const semantics = await page.evaluate(() => {
    const nodes = document.querySelectorAll('flt-semantics, [aria-label]');
    return [...nodes]
      .map((n) => n.getAttribute('aria-label') || n.textContent || '')
      .join(' | ');
  });
  const rendered = `${text} ${semantics}`.toLowerCase();

  await page.screenshot({
    path: `screenshots/route-${label.replace(/\W+/g, '-')}.png`,
  });
  await page.close();

  results.push({
    label,
    path,
    landedOn,
    rendered,
    frameHash,
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
// `/home/:id` must resolve rather than 404 back into the login redirect.
await check('home-with-id', '/home/some-event-id', { expectSupportPage: false });

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

// And it must render the SUPPORT page, not merely keep the URL.
//
// The bug this guards against: a route ordering mistake let `/support` match
// the home route's `:id` child, so the URL said /support (the sidebar even
// highlighted Support) while the body painted Home. The URL check alone passed.
//
// Pixel hashes catch it. Two different screens hash differently; the same
// screen hashes the same. So require the support frame to differ from the login
// frame, which is what the home screen collapsed into when it swallowed the
// route.
const supportFrames = results
  .filter((r) => r.path.startsWith('/support'))
  .map((r) => r.frameHash);
const loginFrame = results.find((r) => r.path === '/')?.frameHash;
const supportContentOk =
  supportFrames.length > 0 &&
  new Set(supportFrames).size === 1 &&
  supportFrames.every((h) => h !== loginFrame);

const rootOk = results.find((r) => r.path === '/')?.landedOn === '/login';
const homeOk =
  results.find((r) => r.path === '/home/some-event-id')?.landedOn === '/login';
const noErrors = results.every((r) => r.hadErrors === 0);

console.log('\n[routes] frame hashes');
for (const r of results) console.log(`  ${r.label.padEnd(26)} ${r.frameHash}`);

console.log('\n[routes] checks');
console.log(`  /support stays public (no bounce to /login): ${supportOk}`);
console.log(
  `  /support renders its own screen (not /login): ${supportContentOk}`,
);
console.log(`  / redirects to /login when signed out:       ${rootOk}`);
console.log(`  /home/:id redirects when signed out:         ${homeOk}`);
console.log(`  no console errors or failed requests:        ${noErrors}`);

const ok = supportOk && supportContentOk && rootOk && homeOk && noErrors;
console.log(`\n[routes] ${ok ? 'PASS' : 'FAIL'}`);
process.exit(ok ? 0 : 1);
