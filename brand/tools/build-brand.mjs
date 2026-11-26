// Generates every Poyshik logo asset from one source of truth.
// Run: npm install && npm run build   (inside brand/tools)
import { mkdirSync, writeFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { Resvg } from '@resvg/resvg-js';
import opentype from 'opentype.js';

const here = dirname(fileURLToPath(import.meta.url));
const out = join(here, '..', 'svg');
mkdirSync(out, { recursive: true });

// ── Palette (see docs/BRAND_GUIDELINES.md) ─────────────────────────────────
export const C = {
  forest: '#123D2E',
  forestDeep: '#0B2A20',
  cream: '#FBF8F1',
  paper: '#F4EEE2',
  marigold: '#E2A13B',
  marigoldLight: '#E9B04E',
};

// ── Symbol: a "P" whose stem ends in a marigold leaf ───────────────────────
// Drawn on a 512 grid. The P body spans y 104–320 (= cap height in lockups);
// the leaf hangs below like a descender.
export const P_PATH =
  'M168 140A36 36 0 0 1 204 104H276A100 100 0 0 1 276 304H248V320H168Z' +
  'M248 160H274A44 44 0 0 1 274 248H248Z';
export const LEAF_PATH = 'M248 334C250 394 220 440 150 468C158 430 168 392 168 334Z';
const MARK = { x: 146, y: 100, w: 234, h: 372 }; // tight bounds incl. leaf tip
const P_TOP = 104;
const P_BASE = 320;

const svg = (vb, body, title) =>
  `<svg xmlns="http://www.w3.org/2000/svg" viewBox="${vb}" role="img" aria-label="${title}">` +
  `<title>${title}</title>${body}</svg>\n`;

const mark = (ink, accent, transform = '') =>
  `<g${transform ? ` transform="${transform}"` : ''}>` +
  `<path d="${P_PATH}" fill="${ink}" fill-rule="evenodd"/>` +
  `<path d="${LEAF_PATH}" fill="${accent}"/></g>`;

// ── Wordmark: "Poyshik" in Instrument Serif, converted to outlines ─────────
const font = opentype.loadSync(
  join(here, '..', '..', 'assets', 'fonts', 'instrument_serif', 'InstrumentSerif-Regular.ttf'),
);
const capHeight = font.tables.os2.sCapHeight; // font units
const TRACKING = -0.012; // em, slightly tight for display

function wordPath(size) {
  let x = 0;
  const parts = [];
  const glyphs = font.stringToGlyphs('Poyshik');
  glyphs.forEach((g, i) => {
    parts.push(g.getPath(x, 0, size).toPathData(2));
    const kern = i < glyphs.length - 1 ? font.getKerningValue(g, glyphs[i + 1]) : 0;
    x += ((g.advanceWidth + kern) / font.unitsPerEm) * size + TRACKING * size;
  });
  const p = font.getPath('Poyshik', 0, 0, size, { kerning: true });
  const bb = p.getBoundingBox();
  return { d: parts.join(''), width: x - TRACKING * size, top: bb.y1, bottom: bb.y2, left: bb.x1 };
}

// Wordmark alone (baseline at y=0 inside its own viewBox)
const W = wordPath(200);
const wordVB = `${(W.left - 2).toFixed(1)} ${(W.top - 2).toFixed(1)} ${(W.width - W.left + 4).toFixed(1)} ${(W.bottom - W.top + 4).toFixed(1)}`;

// ── Horizontal lockup: symbol cap-aligned with the wordmark ────────────────
function lockup(ink, accent, title) {
  const size = 200;
  const capPx = (capHeight / font.unitsPerEm) * size;
  const s = capPx / (P_BASE - P_TOP); // P body == cap height
  const markW = MARK.w * s;
  const gap = capPx * 0.42;
  // Mark placed so P top sits at cap top (-capPx) and stem base on baseline.
  const tx = -MARK.x * s;
  const ty = -capPx - P_TOP * s;
  const wordX = markW + gap;
  const top = Math.min(-capPx, W.top) - 4;
  const bottom = Math.max(ty + (MARK.y + MARK.h) * s, W.bottom) + 4;
  const width = wordX + W.width + 4;
  return svg(
    `-4 ${top.toFixed(1)} ${width.toFixed(1)} ${(bottom - top).toFixed(1)}`,
    mark(ink, accent, `translate(${tx.toFixed(2)} ${ty.toFixed(2)}) scale(${s.toFixed(4)})`) +
      `<path d="${W.d}" fill="${ink}" transform="translate(${wordX.toFixed(2)} 0)"/>`,
    title,
  );
}

// ── Stacked lockup: symbol above, wordmark centred ─────────────────────────
function stacked(ink, accent, title) {
  const size = 200;
  const s = 1.05;
  const markW = MARK.w * s;
  const markH = MARK.h * s;
  const width = Math.max(W.width, markW) + 8;
  const mx = (width - markW) / 2 - MARK.x * s;
  const wordY = markH + 40 - W.top;
  const wx = (width - W.width) / 2;
  return svg(
    `-4 -4 ${width.toFixed(1)} ${(wordY + W.bottom + 8).toFixed(1)}`,
    mark(ink, accent, `translate(${mx.toFixed(2)} ${(-MARK.y * s).toFixed(2)}) scale(${s})`) +
      `<path d="${W.d}" fill="${ink}" transform="translate(${wx.toFixed(2)} ${wordY.toFixed(2)})"/>`,
    title,
  );
}

// App icon master: 512 tile, mark optically centred.
const icon = (bg, ink, accent, title, rx = 112) =>
  svg('0 0 512 512', `<rect width="512" height="512" rx="${rx}" fill="${bg}"/>` + mark(ink, accent, 'translate(-7 -30)'), title);

const files = {
  'poyshik-symbol.svg': svg(`${MARK.x} ${MARK.y} ${MARK.w} ${MARK.h}`, mark(C.forest, C.marigold), 'Poyshik'),
  'poyshik-symbol-on-dark.svg': svg(`${MARK.x} ${MARK.y} ${MARK.w} ${MARK.h}`, mark(C.paper, C.marigoldLight), 'Poyshik'),
  'poyshik-symbol-mono.svg': svg(`${MARK.x} ${MARK.y} ${MARK.w} ${MARK.h}`, mark('currentColor', 'currentColor'), 'Poyshik'),
  'poyshik-wordmark.svg': svg(wordVB, `<path d="${W.d}" fill="${C.forest}"/>`, 'Poyshik'),
  'poyshik-wordmark-on-dark.svg': svg(wordVB, `<path d="${W.d}" fill="${C.paper}"/>`, 'Poyshik'),
  'poyshik-logo-light.svg': lockup(C.forest, C.marigold, 'Poyshik'),
  'poyshik-logo-dark.svg': lockup(C.paper, C.marigoldLight, 'Poyshik'),
  'poyshik-logo-stacked-light.svg': stacked(C.forest, C.marigold, 'Poyshik'),
  'poyshik-logo-stacked-dark.svg': stacked(C.paper, C.marigoldLight, 'Poyshik'),
  'poyshik-app-icon.svg': icon(C.forest, C.cream, C.marigold, 'Poyshik app icon'),
  'poyshik-app-icon-dev.svg': icon(C.cream, C.forest, C.marigold, 'Poyshik Dev app icon'),
  'favicon.svg': icon(C.forest, C.cream, C.marigold, 'Poyshik', 120),
};
for (const [name, content] of Object.entries(files)) writeFileSync(join(out, name), content);
console.log(`Wrote ${Object.keys(files).length} files to ${out}`);

// ── PNG exports (store listing, web icons) ─────────────────────────────────
const png = join(here, '..', 'png');
mkdirSync(png, { recursive: true });
const square = (bg, ink, accent) => // full-bleed: stores/OS apply their own mask
  svg('0 0 512 512', `<rect width="512" height="512" fill="${bg}"/>` + mark(ink, accent, 'translate(-7 -30)'), 'Poyshik');
const renders = [
  ['app-icon-1024.png', files['poyshik-app-icon.svg'], 1024],
  ['app-icon-512.png', files['poyshik-app-icon.svg'], 512],
  ['play-store-icon-512.png', square(C.forest, C.cream, C.marigold), 512],
  ['apple-touch-icon-180.png', square(C.forest, C.cream, C.marigold), 180],
  ['icon-192.png', files['poyshik-app-icon.svg'], 192],
  ['icon-maskable-512.png', square(C.forest, C.cream, C.marigold), 512],
  ['favicon-32.png', files['favicon.svg'], 32],
  ['logo-light-1200.png', files['poyshik-logo-light.svg'], 1200, 'width'],
  ['logo-dark-1200.png', files['poyshik-logo-dark.svg'], 1200, 'width'],
];
for (const [name, source, size, mode] of renders) {
  const r = new Resvg(source, { fitTo: { mode: mode ?? 'width', value: size } });
  writeFileSync(join(png, name), r.render().asPng());
}
console.log(`Wrote ${renders.length} PNGs to ${png}`);
console.log(`capHeight=${capHeight} upm=${font.unitsPerEm}`);
