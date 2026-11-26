// Builds a tiny fallback font containing only the Bengali taka sign (৳,
// U+09F3), taken from Noto Sans Bengali (SIL OFL 1.1). Geist has no ৳, so the
// app lists this as a font fallback: the sign renders identically on every
// device instead of whatever the system font provides.
//   node make-taka-font.mjs
import { mkdirSync, copyFileSync, writeFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import opentype from 'opentype.js';

const here = dirname(fileURLToPath(import.meta.url));
const src = opentype.loadSync(join(here, '_src', 'NotoSansBengali.ttf'));
const taka = src.charToGlyph('৳');
if (!taka || taka.index === 0) throw new Error('No taka glyph in source font');

const notdef = new opentype.Glyph({
  name: '.notdef',
  unicode: 0,
  advanceWidth: src.unitsPerEm / 2,
  path: new opentype.Path(),
});
const glyph = new opentype.Glyph({
  name: 'taka',
  unicode: 0x09f3,
  advanceWidth: taka.advanceWidth,
  path: taka.path, // outline in font units, copied as-is
});

const font = new opentype.Font({
  familyName: 'PoyshikTaka',
  styleName: 'Regular',
  unitsPerEm: src.unitsPerEm,
  ascender: src.ascender,
  descender: src.descender,
  glyphs: [notdef, glyph],
  copyright: 'Glyph from Noto Sans Bengali, Copyright 2022 The Noto Project Authors',
  license: 'SIL Open Font License 1.1',
});

const outDir = join(here, '..', '..', 'assets', 'fonts', 'taka');
mkdirSync(outDir, { recursive: true });
writeFileSync(join(outDir, 'PoyshikTaka.ttf'), Buffer.from(font.toArrayBuffer()));
copyFileSync(join(here, '_src', 'NotoSansBengali-OFL.txt'), join(outDir, 'OFL.txt'));
console.log('Wrote assets/fonts/taka/PoyshikTaka.ttf');
