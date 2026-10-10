// Reads the actual rendered content by enabling Flutter's semantics tree.
//
// Flutter paints into a canvas, so pixels alone cannot say whether the grey is
// a spinner, an error card, or a genuinely empty pane. Turning on semantics
// makes the engine publish the widget text as DOM, which is readable here.
import { chromium } from 'playwright';

const browser = await chromium.launch();
const context = await browser.newContext({
  locale: 'uk-UA',
  viewport: { width: 1280, height: 800 },
});
const page = await context.newPage();

const log = [];
page.on('console', (m) => log.push(`[${m.type()}] ${m.text()}`));
page.on('pageerror', (e) => log.push(`[pageerror] ${e.message}`));

await page.goto('http://127.0.0.1:8099/', { waitUntil: 'load', timeout: 60000 });
await page.waitForTimeout(6000);

// Flutter exposes an "Enable accessibility" placeholder; clicking it turns the
// semantics tree on, which serialises the visible widget tree to the DOM.
const placeholder = page.locator('flt-semantics-placeholder');
if (await placeholder.count()) {
  await placeholder.click({ force: true }).catch(() => { });
  await page.waitForTimeout(5000);
}

const tree = await page.evaluate(() => {
  const host = document.querySelector('flt-semantics-host');
  const collect = (root) => {
    const out = [];
    const walk = (el) => {
      const label = el.getAttribute('aria-label') || el.getAttribute('aria-valuetext');
      const text = el.childNodes.length === 1 && el.firstChild.nodeType === 3
        ? el.textContent.trim()
        : '';
      if (label || text) out.push(label || text);
      [...el.children].forEach(walk);
    };
    if (root) walk(root);
    return out;
  };
  return {
    labels: collect(host),
    semanticsHTML: host ? host.innerHTML.slice(0, 4000) : '(no host)',
  };
});

console.log('--- accessibility labels ---');
console.log(tree.labels.length ? tree.labels.join('\n') : '(none — semantics off)');
console.log('\n--- console ---');
console.log(log.filter((l) => !l.startsWith('[debug]')).join('\n') || '(only debug)');

await browser.close();
