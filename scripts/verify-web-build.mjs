// Verifies the PRUNED web build actually boots.
//
// The prune step deletes ~27 MB of staged renderer files, and a wrong guess
// there produces a blank white page rather than an error anyone would notice in
// CI. So this loads the real build in a real browser and checks that Flutter
// initialised, the app painted something, and nothing failed to load.
//
//   node scripts/verify-web-build.mjs
//
// Exits non-zero if the page is blank or a request 404s, so it is safe to wire
// into a release check.

import { createServer } from 'node:http';
import { readFile } from 'node:fs/promises';
import { extname, join, normalize } from 'node:path';
import { chromium } from 'playwright';

const ROOT = 'build/web';
const PORT = 8099;

// Counts distinct RGB values in a PNG buffer.
//
// Decoded with Chromium itself rather than a PNG library: the browser is
// already open, and `createImageBitmap` + a 2D canvas handles every PNG
// variant Flutter's screenshot might produce. A blank page is one colour; a
// painted one is dozens.
async function countColours(pngBuffer, samplePage) {
  const base64 = pngBuffer.toString('base64');
  return samplePage.evaluate(async (data) => {
    const response = await fetch(`data:image/png;base64,${data}`);
    const blob = await response.blob();
    const bitmap = await createImageBitmap(blob);
    const scratch = document.createElement('canvas');
    scratch.width = bitmap.width;
    scratch.height = bitmap.height;
    const ctx = scratch.getContext('2d');
    ctx.drawImage(bitmap, 0, 0);
    const { data: px } = ctx.getImageData(0, 0, bitmap.width, bitmap.height);
    const seen = new Set();
    for (let i = 0; i < px.length; i += 4) {
      seen.add(`${px[i]},${px[i + 1]},${px[i + 2]}`);
    }
    return { ok: seen.size > 1, colours: seen.size };
  }, base64);
}

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
  // Flutter requests the wasm binary as a stream and inspects this header.
  '.symbols': 'application/octet-stream',
};

const server = createServer(async (req, res) => {
  const url = decodeURIComponent((req.url ?? '/').split('?')[0]);
  let path = normalize(join(ROOT, url === '/' ? '/index.html' : url));
  if (!path.startsWith(normalize(ROOT))) {
    res.writeHead(403).end();
    return;
  }
  try {
    const body = await readFile(path);
    res.writeHead(200, {
      'Content-Type': TYPES[extname(path)] ?? 'application/octet-stream',
      'Cache-Control': 'no-store',
    });
    res.end(body);
  } catch {
    // index.html fallback mirrors how hosting serves a SPA.
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
console.log(`[verify] serving ${ROOT} on http://127.0.0.1:${PORT}`);

const browser = await chromium.launch();
const page = await browser.newPage({ viewport: { width: 1280, height: 900 } });

const consoleErrors = [];
const failedRequests = [];
page.on('console', (msg) => {
  if (msg.type() === 'error') consoleErrors.push(msg.text());
});
page.on('pageerror', (error) => consoleErrors.push(String(error)));
page.on('requestfailed', (req) =>
  failedRequests.push(`${req.url()} - ${req.failure()?.errorText}`),
);
page.on('response', (res) => {
  if (res.status() >= 400) failedRequests.push(`${res.status()} ${res.url()}`);
});

await page.goto(`http://127.0.0.1:${PORT}/`, {
  waitUntil: 'load',
  timeout: 60000,
});

// Flutter paints into a canvas, so there is no DOM text to assert on. Wait for
// the framework to attach its view, then give the first frame time to paint.
try {
  await page.waitForSelector('flutter-view, flt-glass-pane, canvas', {
    timeout: 45000,
  });
} catch {
  console.error('[verify] Flutter never attached a view - the app did not boot.');
  await page.screenshot({ path: 'screenshots/web-build-blank.png' });
  await browser.close();
  server.close();
  process.exit(1);
}

await page.waitForTimeout(5000);

// A painted frame is not a blank frame.
//
// Reading the pixels back is fiddly: CanvasKit renders into a WebGL canvas, and
// `ctx.drawImage(webglCanvas, ...)` into a 2D context returns an empty buffer
// even when the page is clearly painted — a false negative that made this
// script report `0 colours` for a perfectly good build.
//
// Instead, ask Chromium itself: `page.screenshot()` captures the composited
// frame properly, so decode that PNG and count distinct colours. One colour
// means a blank screen; anything more means something was drawn.
const shot = await page.screenshot({ clip: { x: 0, y: 0, width: 400, height: 300 } });
const painted = await countColours(shot, page);

const title = await page.title();
await page.screenshot({ path: 'screenshots/web-build.png', fullPage: false });

await browser.close();
server.close();

console.log('\n[verify] results');
console.log(`  title:            ${title}`);
console.log(`  painted:          ${painted.ok} (${painted.colours ?? 0} colours)`);
console.log(`  console errors:   ${consoleErrors.length}`);
console.log(`  failed requests:  ${failedRequests.length}`);

for (const error of consoleErrors.slice(0, 10)) console.log(`    err  ${error}`);
for (const request of failedRequests.slice(0, 10))
  console.log(`    req  ${request}`);

const ok = painted.ok && consoleErrors.length === 0 && failedRequests.length === 0;
console.log(`\n[verify] ${ok ? 'PASS' : 'FAIL'}`);
process.exit(ok ? 0 : 1);
