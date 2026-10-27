#!/usr/bin/env node
/**
 * Generate every Flutter app icon and splash asset from one inline SVG source.
 *
 *   node scripts/generate-flutter-icons.mjs
 *
 * Why code instead of checked-in PNGs: the mark must match the Until brand
 * (dark canvas, cream clock, teal dashed ring) across Android adaptive icons,
 * iOS AppIcon sets, the web PWA icons and the splash screens. Keeping it as
 * one source means a palette change re-propagates everywhere in a single run
 * rather than by re-exporting from a design tool.
 *
 * Geometry matches `public/favicon.svg` (the React app's mark) — a dark tile
 * with a cream clock — scaled to every size the three platforms require.
 *
 * Outputs:
 *   assets/icon/    1024px icon + adaptive foreground/background layers
 *   assets/splash/  light and dark splash canvases
 *   web/icons/      PWA icons
 *   web/favicon.png
 */
import { mkdirSync, writeFileSync } from "node:fs";
import { dirname, join } from "node:path";
import sharp from "sharp";

const ROOT = process.cwd();

// The app palette, matching lib/core/theme.dart.
const BG = "#0E1113";
const CREAM = "#F0F1EE";
const ACCENT = "#4FD1C5";

/**
 * The clock mark on a transparent canvas.
 *
 * `withPlate` draws the rounded-square tile that legacy/fallback icons need.
 * Android's adaptive icon is masked to roughly the inner 66% "safe zone", so
 * the mark is drawn at 62% of the canvas to survive every mask shape (circle,
 * squircle, rounded square) without clipping.
 */
function clockMark({ size, withPlate }) {
  const c = size / 2;
  const s = size * 0.62;
  const r = s * 0.26;
  const strokeW = s * 0.055;
  const plate = withPlate
    ? `<rect x="0" y="0" width="${size}" height="${size}" rx="${size * 0.22}" fill="${BG}"/>`
    : "";
  return `<svg xmlns="http://www.w3.org/2000/svg" width="${size}" height="${size}" viewBox="0 0 ${size} ${size}">
  ${plate}
  <g transform="translate(${c} ${c})">
    <circle cx="0" cy="0" r="${r}" fill="none" stroke="${CREAM}" stroke-width="${strokeW}"/>
    <circle cx="0" cy="0" r="${r * 1.42}" fill="none" stroke="${ACCENT}" stroke-width="${strokeW * 0.7}" opacity="0.55" stroke-dasharray="${s * 0.02} ${s * 0.05}"/>
    <path d="M0 ${-r * 0.62} V0 L${r * 0.5} ${r * 0.3}"
          fill="none" stroke="${CREAM}" stroke-width="${strokeW}" stroke-linecap="round" stroke-linejoin="round"/>
  </g>
</svg>`;
}

/** Full-bleed splash canvas with the mark centred. */
function splash({ size, dark }) {
  const c = size / 2;
  const background = dark ? BG : CREAM;
  const hand = dark ? CREAM : BG;
  return `<svg xmlns="http://www.w3.org/2000/svg" width="${size}" height="${size}" viewBox="0 0 ${size} ${size}">
  <rect width="${size}" height="${size}" fill="${background}"/>
  <g transform="translate(${c} ${c})">
    <circle r="${size * 0.115}" fill="none" stroke="${hand}" stroke-width="${size * 0.018}"/>
    <circle r="${size * 0.16}" fill="none" stroke="${ACCENT}" stroke-width="${size * 0.012}" opacity="0.5" stroke-dasharray="${size * 0.006} ${size * 0.016}"/>
    <path d="M0 ${-size * 0.071} V0 L${size * 0.058} ${size * 0.035}"
          fill="none" stroke="${hand}" stroke-width="${size * 0.018}" stroke-linecap="round" stroke-linejoin="round"/>
  </g>
</svg>`;
}

/** The SVG favicon — same geometry, no raster, for browsers that prefer it. */
const svgFavicon = `<svg xmlns="http://www.w3.org/2000/svg" width="64" height="64" viewBox="0 0 64 64">
  <rect width="64" height="64" rx="14" fill="${BG}"/>
  <g transform="translate(32 32)">
    <circle r="17" fill="none" stroke="${CREAM}" stroke-width="3.5"/>
    <path d="M0 -10.5 V0 L8.5 5" fill="none" stroke="${CREAM}" stroke-width="3.5" stroke-linecap="round" stroke-linejoin="round"/>
  </g>
</svg>`;

async function png(svg, outPath, size) {
  const buf = await sharp(Buffer.from(svg)).resize(size, size).png().toBuffer();
  const target = join(ROOT, outPath);
  mkdirSync(dirname(target), { recursive: true });
  writeFileSync(target, buf);
  console.log(`[icons] ${outPath} (${buf.length} bytes)`);
}

// --- icon + adaptive layers, consumed by flutter_launcher_icons ---
await png(clockMark({ size: 1024, withPlate: true }), "assets/icon/icon.png", 1024);
await png(clockMark({ size: 1024, withPlate: false }), "assets/icon/icon-foreground.png", 1024);
await png(
  `<svg xmlns="http://www.w3.org/2000/svg" width="1024" height="1024"><rect width="1024" height="1024" fill="${BG}"/></svg>`,
  "assets/icon/icon-background.png",
  1024,
);

// --- splash, consumed by flutter_native_splash ---
await png(splash({ size: 1024, dark: true }), "assets/splash/splash-dark.png", 1024);
await png(splash({ size: 1024, dark: false }), "assets/splash/splash.png", 1024);

// --- web PWA + favicon ---
await png(clockMark({ size: 512, withPlate: true }), "web/icons/Icon-512.png", 512);
await png(clockMark({ size: 256, withPlate: true }), "web/icons/Icon-192.png", 192);
await png(clockMark({ size: 256, withPlate: true }), "web/favicon.png", 64);

// The maskable variant keeps the mark inside the safe circle Android and iOS
// crop to when a PWA is pinned to a home screen.
await png(clockMark({ size: 512, withPlate: false }), "web/icons/Icon-maskable-512.png", 512);

const svgTarget = join(ROOT, "web/icons/until-mark.svg");
mkdirSync(dirname(svgTarget), { recursive: true });
writeFileSync(svgTarget, svgFavicon);
console.log("[icons] web/icons/until-mark.svg");

console.log("\n[icons] done.");
console.log("Next:");
console.log("  dart run flutter_launcher_icons   # Android + iOS app icons");
console.log("  dart run flutter_native_splash    # Android + iOS splash screens");