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
| `PUBLIC_APK_VERSION`    | Version label shown under a direct APK download, e.g. `1.1.0`.                     |
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

Live at **https://poyshik.vercel.app** (Vercel project `poyshik`).

The project is connected to this GitHub repository, so deploys are automatic:

- **Push to `main`** → production deploy to poyshik.vercel.app.
- **Push any other branch / open a PR** → a preview deploy with its own URL.
- Commits that don't touch `website/` are skipped (Ignored Build Step:
  `git diff --quiet HEAD^ HEAD ./`), so app-only changes don't rebuild the site.

Project settings: Root Directory `website`, framework Astro (build `npm run build`,
output `dist`), production branch `main`. Production environment variables:
`SITE_URL`, `PUBLIC_APK_URL`, `PUBLIC_APK_VERSION` (change them in the Vercel
dashboard, then redeploy).

**Shipping a new app version:** build the signed APK, publish a GitHub Release with
the file named `poyshik.apk` (the site links to `releases/latest/download/poyshik.apk`,
so the link never changes), then update `PUBLIC_APK_VERSION` and redeploy.

## Deploy to GitHub Pages

A manual workflow is included at `.github/workflows/website-pages.yml` (it never runs on push).

1. Repository **Settings → Pages → Source: GitHub Actions**.
2. Set repository variables `SITE_URL` (e.g. `https://<user>.github.io`) and `BASE_PATH` (e.g. `/poyshik`) under **Settings → Secrets and variables → Actions → Variables**.
3. **Actions → Deploy website to GitHub Pages → Run workflow.**

## Before going public

- `src/pages/privacy.astro` and `terms.astro` are **drafts** (marked `noindex`). The owner must complete them; Google Play requires a privacy policy.
- Set `SITE_URL` and the download URL(s) once they exist.
