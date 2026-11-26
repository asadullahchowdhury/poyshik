# Progress log — product polish

Branch `polish/brand-and-website` (uncommitted, per instructions). Newest first.

- **Phase 7 — Final QA** ✅
  - Flutter: `dart format` clean (86 files) · `flutter analyze` clean · 99/99 tests · debug APK ✅ · signed release APK ✅ (arm64 21.0 MB).
  - Website: Prettier clean · `astro check` 0 errors/warnings · build ✅ (4 pages, 2.4 KB JS, 24.5 KB CSS, screenshots → WebP 45–71 KB) · GitHub Pages sub-path build verified (all 69 asset URLs prefixed) · browser review desktop 1440 + mobile 390 (no horizontal overflow) · showcase tabs/dark toggle work · no console errors · 1 h1, all images have alt, all anchors/pages resolve, zero external links.
  - **Not verified:** on-device install/run of the redesign — the phone was not connected (`adb devices` empty) during this session.
- **Phase 4–6 — Website** ✅ `/website` (Astro 7 static): hero, how-it-works, interactive showcase (real screens, light/dark), bento features, insights (animated chart, labelled demo), privacy & offline (claims match the app), CTA with configurable download (shows "Coming soon" until a URL is set), footer, draft privacy/terms (noindex), 404, SEO/OG/manifest/favicons; Vercel-ready; manual GitHub Pages workflow `.github/workflows/website-pages.yml`.

- **Phase 2–3 — App redesign + motion** ✅ (device install pending: phone not connected)
  - Tokens: forest/paper/marigold palette (light + dark), hero tokens, earthy category palette; Instrument Serif display voice; bundled 1.8 KB `PoyshikTaka` fallback so ৳ renders identically everywhere.
  - Theme: forest primary, serif screen titles, themed segmented buttons, switches, dialogs, progress, sheets (forest scrim), snackbars, FadeForwards page transitions.
  - Components: `PoyshikSymbol`/`PoyshikLogo` (vector, same geometry as brand SVG), `PillChip` (replaces 3 duplicates), `SectionHeader`/`SectionAction`, `LoadingView`/`ErrorView`, `PoyshikCard` (press-scale, elevated hero), `AnimatedAmountText`, motion kit (`Reveal`, `Pressable`, `Pulse`, `Motion.reduced`), `SuccessCheck` snackbar.
  - Screens: Home (greeting header, forest hero with count-up total, comparison pill, budget bar, safe-to-spend, income/net, watermark), Accounts (hero total), Insights (full-width period control, serif period label, outlier-aware bars + average line + legend, animated growth, staggered cards), Activity (staggered day groups, proper loading/error), entry sheet (PillChips, amount settle on key press, success check), nav bar (active pill, raised marigold add button), welcome (real logo + serif wordmark, staggered reveal).
  - Launcher icon → brand mark (adaptive + themed + legacy); Dev build uses the inverted cream icon; splash/window colours follow paper/night.
  - Reduced motion respected everywhere (`MediaQuery.disableAnimations`).
  - Checks: `flutter analyze` clean · 99 tests pass (+3 bar-scale tests) · debug APK builds · 10 screenshots rendered.
  - Incident (fixed): a PowerShell bulk-replace bug corrupted 3 files mid-phase (`category_form_sheet`, `palette_picker`, `add_transaction_sheet`); restored from `HEAD` content and re-applied intended edits; repo scanned clean; all checks re-run.
- **Screenshot pipeline** ✅ `screenshots/` renders real screens with labelled demo data (`flutter test screenshots --update-goldens` → `screenshots/out/*.png`, 1200×2598).
- **Phase 1 — Brand** ✅ `brand/` (generator `brand/tools`, SVG system, PNG exports), `docs/BRAND_GUIDELINES.md`.
- **Phase 0 — Audit** ✅ `docs/PRODUCT_POLISH_PLAN.md`. Baseline: analyze clean, 96 tests at `v1.0.0`.
