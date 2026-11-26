// @ts-check
import { defineConfig } from 'astro/config';

// SITE_URL: the public origin, used for canonical URLs, Open Graph and the
// sitemap-free robots.txt. BASE_PATH: set to "/<repo>" for GitHub Pages
// project sites; leave empty for Vercel or a custom domain.
const site = process.env.SITE_URL || 'https://poyshik.example';
const base = process.env.BASE_PATH || '/';

export default defineConfig({
  site,
  base,
  trailingSlash: 'ignore',
  build: { format: 'directory' },
  image: {
    // Screenshots are optimised to WebP at build time (sharp ships with Astro).
    responsiveStyles: true,
  },
  prefetch: { prefetchAll: false },
});
