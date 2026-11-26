# Poyshik — Product Polish Plan

_Audit date: 2026-11-26 · Baseline: `v1.0.0` (main @ 4acdb67) · Work branch: `polish/brand-and-website` (uncommitted)_

## 1. Audit

### Stack & architecture (keep)
| Area | Current | Verdict |
|---|---|---|
| Framework | Flutter 3.50.1 / Dart 3.14, **`material_ui`** package (3.50 split) | Keep |
| State | Riverpod 3 (manual providers, `StreamProvider`/`Notifier`) | Keep |
| Data | Drift + SQLite, schema v1, UUIDs, money as `int` poisha | Keep — no schema change needed |
| Navigation | GoRouter `StatefulShellRoute` (4 tabs + centre add), `/welcome` onboarding redirect | Keep |
| Charts | `fl_chart` 1.3.1 | Keep |
| Layout | Feature-first `lib/features/*`, shared `lib/core/*`, theme in `lib/app/theme` | Keep |
| Tests | 96 (unit, repository on in-memory DB, widget tests with provider overrides) | Keep green |
| Run | VS Code + physical Redmi Note 10 Pro Max over USB/adb (no emulator) | — |

### Working features (must not regress)
Accounts (balances, archive) · quick entry (expense/income/transfer, numpad, usage-ordered categories, last account, undo) · Activity (day groups, edit, swipe-delete+undo, search & filters) · Home dashboard (month spend vs last month, budget & safe-to-spend, today/week, accounts, top categories, recent) · Insights (week/month, highlights, daily bars, donut) · Categories (CRUD, reorder, archive) · Budget · Settings (theme, week start) · Backup/restore JSON + CSV · Onboarding · Dev/release flavours, release signing.

### UI weaknesses
1. **Brand**: ink-black + marigold reads generic; launcher icon is an abstract ring with no "Poyshik" recognition; no wordmark, no logo system.
2. **Dashboard**: a stack of equal white cards — no hierarchy, no hero moment; plain "November 2026" app bar.
3. **Inconsistent controls**: stock `SegmentedButton` (Categories, Insights, Settings), stock `AlertDialog`, stock `Switch`, three near-duplicate pill-chip widgets (`_Chip`, `_InfoChip`, `_FilterChip`).
4. **States**: loading is a blank `SizedBox.shrink()`; errors print raw exceptions (`Text('$e')`); empty states are static.
5. **Typography**: one family (Geist) for everything — no display voice for titles/hero moments.
6. **Motion**: almost none — numbers jump, charts pop in, default page transitions, no feedback after saving beyond a snackbar.
7. **Dev gallery** shows obsolete sample UI.

### Technical debt relevant to this work
- Duplicated section-header / pill-chip / settings-section helpers across 5 files → consolidate into `core/widgets`.
- Colors are referenced through `context.colors` everywhere (good) → a palette change is centralised in `colors.dart`.
- No screenshot pipeline → add golden-based screenshot generation with demo data (also usable for the website).

## 2. Execution plan

| Phase | Deliverable | Verification |
|---|---|---|
| 0 | This audit, `docs/PROGRESS.md` | — |
| 1 Brand | `brand/` SVG symbol, wordmark, lockups (light/dark), app-icon master, palette & type; `docs/BRAND_GUIDELINES.md` | Render SVGs in browser, check small sizes |
| 2 App UI | New tokens (forest/cream/marigold), display serif, unified components (pill chips, segmented control, sheets, dialogs, states), redesigned Home / entry / Activity / Insights / Accounts / Categories / Settings / nav; new launcher icon | format, analyze, all tests, debug+release build, install on phone |
| 3 Motion | Animated amounts, staggered reveals, press-scale, chart animation, page transitions, save feedback; honours "remove animations" | analyze/tests, build |
| 3b Screens | `test/screenshots/` golden pipeline rendering real screens with clearly-labelled demo data → PNGs for the website | generated images inspected |
| 4–5 Website | `/website` (Astro, static): hero, showcase with real screenshots, features, insights, workflow, privacy, CTA, footer; scroll reveals, light parallax, reduced-motion | `astro check`, lint, build, browser check (desktop/mobile), console |
| 6 Deploy | README, Vercel + GitHub Pages config, SEO/OG, favicon | production build |
| 7 QA | Final checks, `docs/PROGRESS.md`, report | — |

### Guardrails
- No commits/pushes/deploys (per instructions) — everything stays as working-tree changes on `polish/brand-and-website`.
- No schema changes, no data migration, no user data touched.
- Screenshots use **demo data rendered by the real widgets**, labelled as such; never the user's real data.
- No invented store links, testimonials, company details or security claims.
