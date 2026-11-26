// Social preview image (1200×630): logo, promise, and the real Home screen.
//   node make-og.mjs   (after the screenshots and build-brand have run)
import { readFileSync, writeFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { Resvg } from '@resvg/resvg-js';

const here = dirname(fileURLToPath(import.meta.url));
const root = join(here, '..', '..');
const logo = readFileSync(join(root, 'brand', 'svg', 'poyshik-logo-dark.svg'), 'utf8');
const shot = readFileSync(join(root, 'screenshots', 'out', 'home_light.png')).toString('base64');
const logoBody = logo.replace(/^<svg[^>]*>/, '').replace(/<\/svg>\s*$/, '').replace(/<title>.*?<\/title>/, '');
const logoVB = logo.match(/viewBox="([^"]+)"/)[1].split(' ').map(Number);
const logoH = 64;
const logoScale = logoH / logoVB[3];

// Instrument Serif isn't available to resvg by name, so the headline is the
// outlined wordmark lockup plus Geist text loaded from the repo fonts.
const svg = `<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="1200" height="630" viewBox="0 0 1200 630">
  <rect width="1200" height="630" fill="#0B2A20"/>
  <circle cx="1040" cy="120" r="420" fill="#123D2E"/>
  <g transform="translate(80 92) scale(${logoScale}) translate(${-logoVB[0]} ${-logoVB[1]})">${logoBody}</g>
  <text x="80" y="300" font-family="Geist" font-weight="600" font-size="56" fill="#F4EEE2" letter-spacing="-1.5">Every taka,</text>
  <text x="80" y="368" font-family="Geist" font-weight="600" font-size="56" fill="#E9B04E" letter-spacing="-1.5">accounted for.</text>
  <text x="80" y="440" font-family="Geist" font-size="26" fill="#B7C8BD">A calm daily expense tracker for Android.</text>
  <text x="80" y="478" font-family="Geist" font-size="26" fill="#B7C8BD">Offline. No account. Your data stays on your phone.</text>
  <g transform="translate(830 70) rotate(4)">
    <rect x="-12" y="-12" width="264" height="556" rx="44" fill="#06150F"/>
    <clipPath id="screen"><rect width="240" height="532" rx="34"/></clipPath>
    <image width="240" height="520" y="0" clip-path="url(#screen)" href="data:image/png;base64,${shot}"/>
  </g>
</svg>`;

const png = new Resvg(svg, {
  font: {
    fontFiles: [
      join(root, 'assets', 'fonts', 'geist', 'Geist-Regular.ttf'),
      join(root, 'assets', 'fonts', 'geist', 'Geist-SemiBold.ttf'),
    ],
    loadSystemFonts: false,
    defaultFontFamily: 'Geist',
  },
}).render().asPng();
writeFileSync(join(root, 'brand', 'png', 'og-image.png'), png);
console.log('Wrote brand/png/og-image.png');
