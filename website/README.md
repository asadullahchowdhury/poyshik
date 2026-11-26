# Poyshik website

The landing page for **Poyshik** — _Every taka, accounted for._ A static [Astro](https://astro.build) site: no server, no secrets, no tracking.

- **Stack:** Astro 7 (static output), self-hosted fonts (Instrument Serif + Geist via Fontsource), plain CSS, ~3 KB of TypeScript for motion. No UI framework.
- **Images:** real app screens, rendered from the Flutter widgets with demo data (`/screenshots` in the repo), converted to WebP at build time.
- **Motion:** scroll reveals, light parallax, floating hero, animated bars and budget bar, showcase transitions. Everything honours `prefers-reduced-motion`; content is visible without JavaScript.

## Requirements

Node.js **22.23.4 or newer** (Astro 7). Tested with Node 24.

## Develop

```bash
cd website
npm install
npm run dev        # http://localhost:4321
```

## Checks

```bash
npm run check          # astro check (TypeScript + .astro diagnostics)
npm run format:check   # Prettier
npm run build          # production build → dist/
npm run preview        # serve dist/ locally
```

## Configuration

Copy `.env.example` to `.env` (or set the same variables in your host's dashboard). All are optional.

| Variable                | Purpose                                                                            |
| ----------------------- | ---------------------------------------------------------------------------------- |
| `SITE_URL`              | Public origin, e.g. `https://poyshik.app`. Used for canonical and Open Graph URLs. |
| `BASE_PATH`             | GitHub Pages project sites only: `/<repo-name>`. Leave empty elsewhere.            |
| `PUBLIC_PLAY_STORE_URL` | Google Play listing. When empty, the page says _Coming soon to Android_.           |
| `PUBLIC_APK_URL`        | A direct APK download (e.g. a GitHub Release asset), if offered.                   |
| `PUBLIC_CONTACT_EMAIL`  | Adds a Contact link to the footer.                                                 |

Download buttons only ever link to a URL you configure — nothing is invented.

## Updating screenshots and brand assets

```bash
# from the repo root: re-render app screens (real widgets, demo data)
flutter test screenshots --update-goldens

# brand assets (logo SVGs, icons, Open Graph image)
cd brand/tools && npm install && npm run build && node make-og.mjs

# copy both into the website
cd website && npm run sync-assets
```

## Deploy to Vercel

1. Import the repository in Vercel.
2. **Root Directory:** `website`. Vercel detects Astro; build command `npm run build`, output `dist`.
3. Add environment variables (at least `SITE_URL`). Deploy.

## Deploy to GitHub Pages

A manual workflow is included at `.github/workflows/website-pages.yml` (it never runs on push).

1. Repository **Settings → Pages → Source: GitHub Actions**.
2. Set repository variables `SITE_URL` (e.g. `https://<user>.github.io`) and `BASE_PATH` (e.g. `/poyshik`) under **Settings → Secrets and variables → Actions → Variables**.
3. **Actions → Deploy website to GitHub Pages → Run workflow.**

## Before going public

- `src/pages/privacy.astro` and `terms.astro` are **drafts** (marked `noindex`). The owner must complete them; Google Play requires a privacy policy.
- Set `SITE_URL` and the download URL(s) once they exist.
