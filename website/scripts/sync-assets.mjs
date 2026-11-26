// Copies brand assets and the latest app screenshots into the website.
// Run after regenerating either:
//   (repo root) flutter test screenshots --update-goldens
//   (brand/tools) npm run build
//   (website)    npm run sync-assets
import { copyFileSync, existsSync, mkdirSync, readdirSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const site = join(dirname(fileURLToPath(import.meta.url)), '..');
const repo = join(site, '..');

const copies = [
  // App screenshots (real widgets, demo data) → optimised by astro:assets.
  [join(repo, 'screenshots', 'out'), join(site, 'src', 'assets', 'screens'), /\.png$/],
  // Brand SVGs for the page.
  [join(repo, 'brand', 'svg'), join(site, 'src', 'assets', 'brand'), /\.svg$/],
];
for (const [from, to, pattern] of copies) {
  if (!existsSync(from)) throw new Error(`Missing ${from}`);
  mkdirSync(to, { recursive: true });
  for (const f of readdirSync(from).filter((n) => pattern.test(n))) {
    copyFileSync(join(from, f), join(to, f));
  }
}

// Public files served as-is.
const pub = join(site, 'public');
mkdirSync(join(pub, 'fonts'), { recursive: true });
const singles = [
  [join(repo, 'brand', 'svg', 'favicon.svg'), join(pub, 'favicon.svg')],
  [join(repo, 'brand', 'png', 'favicon-32.png'), join(pub, 'favicon-32.png')],
  [join(repo, 'brand', 'png', 'apple-touch-icon-180.png'), join(pub, 'apple-touch-icon.png')],
  [join(repo, 'brand', 'png', 'icon-192.png'), join(pub, 'icon-192.png')],
  [join(repo, 'brand', 'png', 'icon-maskable-512.png'), join(pub, 'icon-512.png')],
  [join(repo, 'brand', 'png', 'og-image.png'), join(pub, 'og-image.png')],
  [join(repo, 'assets', 'fonts', 'taka', 'PoyshikTaka.ttf'), join(pub, 'fonts', 'PoyshikTaka.ttf')],
];
for (const [from, to] of singles) copyFileSync(from, to);
console.log('Synced screenshots, brand assets and icons.');
