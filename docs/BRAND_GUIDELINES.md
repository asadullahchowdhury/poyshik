# Poyshik Brand Guidelines

> **Poyshik** — *Every taka, accounted for.*
> A calm, premium personal expense tracker. Warm paper, deep forest ink, one marigold accent.

All assets are generated from one source: `brand/tools/build-brand.mjs` (`npm install && npm run build` inside `brand/tools`). Never edit the SVGs by hand.

## 1. Concept

The reference board explored wallets, coins, bar charts and a **"P" with a leaf**. The wallet and chart ideas are common in fintech and lose detail at icon size. The **P-with-leaf** was the strongest and most ownable, so it was refined into the final symbol:

- **The P**: a geometric, heavy letter with a softened top-left corner. It's legible at 16 px and stable as a launcher icon.
- **The marigold leaf**: the P's stem ends in a curved, tapering leaf. It reads as **growth** (money that's looked after) and as a **quill nib** (keeping a ledger: "accounted for"). The small cut between stem and leaf keeps both shapes crisp at small sizes.
- In lockups, the P's body matches the wordmark's **cap height**, and the leaf drops below the baseline like a descender. Symbol and word share one baseline.

## 2. Logo system (`brand/svg/`)

| File | Use |
|---|---|
| `poyshik-logo-light.svg` | Primary horizontal logo on cream/light backgrounds |
| `poyshik-logo-dark.svg` | Horizontal logo on forest/dark backgrounds |
| `poyshik-logo-p-light.svg` / `-dark.svg` | **P + oyshik**: the symbol is the first letter. Used where the logo can move (website header and footer, app Home and welcome) |
| `poyshik-logo-stacked-light.svg` / `-dark.svg` | Square-ish spaces (splash, social avatars, print) |
| `poyshik-symbol.svg` / `-on-dark.svg` | Symbol alone: favicons, small UI, watermarks |
| `poyshik-symbol-mono.svg` | One colour (`currentColor`): embossing, single-ink print |
| `poyshik-wordmark.svg` / `-on-dark.svg` | Wordmark alone, when the symbol already appears nearby |
| `poyshik-app-icon.svg` | App icon master (forest tile, cream P, marigold leaf) |
| `poyshik-app-icon-dev.svg` | Development build icon (cream tile, forest P). Never use publicly |
| `favicon.svg` | Browser favicon |

PNG exports in `brand/png/`: Play Store icon 512 (full-bleed), 1024/512 rounded icons, maskable 512, Apple touch 180, 192, favicon 32, 1200 px logos.

**P + oyshik in motion:** the P lands first, then "oyshik" slides out from behind its bowl (website header: once per page load; app: once on Home and on the welcome screen). Keep "oyshik" tight to the bowl so the symbol reads as a letter. Where the logo is small, static or seen by people who don't know the name yet (store listing, share images, print), use the full `poyshik-logo-*` lockup.

**Clear space:** keep at least the height of the P's counter (≈ ⅓ of the cap height) free on every side.
**Minimum size:** symbol 16 px; horizontal logo 96 px wide (below that, use the symbol).
**Don't:** recolour the leaf, stretch, add shadows, glows or gradients, outline, rotate, put the light logo on busy photos, or retype the wordmark in another font.

## 3. Colour

| Token | Hex | Role |
|---|---|---|
| **Forest** | `#123D2E` | Brand primary, primary actions, logo ink |
| Forest Deep | `#0B2A20` | Dark surfaces, hero backgrounds |
| Forest Night | `#0C1713` | App background in dark mode |
| **Paper** | `#F4EEE2` | App/web background (light) |
| Cream | `#FBF8F1` | Cards and sheets (light) |
| Sand | `#E9E1D0` | Hairlines, raised fills (light) |
| **Marigold** | `#E2A13B` | The one accent: leaf, add button, highlights |
| Marigold Light | `#E9B04E` | Accent on dark backgrounds |
| Ink | `#17201B` | Body text on light (green-black, never pure black) |
| Sage | `#8AA893` | Secondary botanical tone, charts |
| Coral (expense) | `#C2553F` | Expense emphasis, used sparingly |
| Leaf (income) | `#2F7D5B` | Income |
| Slate (transfer) | `#5D6E8C` | Transfers |

**Ratios:** about 70% paper/cream, 25% forest/ink, under 5% marigold. Marigold is a *signal*. If everything is gold, nothing is.
Money colours are calm by design: expenses are shown in ink with a "−", and coral only where emphasis is needed (budget warnings).

## 4. Typography

| Role | Typeface | Notes |
|---|---|---|
| Display | **Instrument Serif** (OFL) | Wordmark, screen titles, hero statements. Regular weight only; slight negative tracking |
| UI & numbers | **Geist** (OFL), 400–700 | Everything else. Amounts use **tabular figures** and tight tracking |

The pairing gives editorial warmth (serif) with modern precision (Geist). Fonts are bundled in the app (`assets/fonts`) and self-hosted on the website, never fetched from third-party CDNs at runtime in the app.

Scale (app): display 34/40 serif · title 24 serif · hero amount 44 Geist Bold · amount 18–30 · body 15 · label 13 · caption 12 · overline 11 caps +1 tracking.

## 5. Shape, space, depth

- 4 px spacing grid; screen gutter 20 px.
- Radii: 10 / 14 / 20 / 28; app icon tile 22%.
- Depth: hairline borders and **one** soft shadow level for floating elements (sheets, the hero card). No glassmorphism, no glow.
- Icons: Material *rounded* family on category tiles tinted at about 14% of the category colour.

## 6. Motion

Short and purposeful: 150–350 ms, ease-out (`Curves.easeOutCubic` / `cubic-bezier(.2,.8,.2,1)`). Numbers count up, lists stagger in once, charts grow from the baseline. No bouncing, no looping decoration. Everything respects the OS "reduce motion" setting.

## 7. Voice

Plain, warm, confident: *"Every taka, accounted for."* · *"Log an expense in about three seconds."* No hype, no fear ("you're overspending!"). Prefer facts ("৳1,250 a day is safe to spend").
