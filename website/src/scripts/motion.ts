// Motion for the landing page. Dependency-light: Lenis for smooth scrolling,
// everything else is a single rAF loop writing CSS custom properties.
// Without JS content is simply visible; with "reduce motion" everything is
// static (no smooth scroll, no parallax, no scroll-scrubbed effects).
import Lenis from 'lenis';
import 'lenis/dist/lenis.css';

const reduced = () => window.matchMedia('(prefers-reduced-motion: reduce)').matches;
const clamp = (v: number, a = 0, b = 1) => Math.min(b, Math.max(a, v));

/** Buttery wheel/trackpad scrolling; anchors glide and account for the header. */
function smoothScroll() {
  if (reduced()) return;
  const lenis = new Lenis({
    lerp: 0.085,
    smoothWheel: true,
    anchors: { offset: -72 },
  });
  // Handy for debugging and for any future scripted scrolling.
  (window as unknown as { lenis?: Lenis }).lenis = lenis;
  const raf = (t: number) => {
    lenis.raf(t);
    requestAnimationFrame(raf);
  };
  requestAnimationFrame(raf);
}

/** Fade/lift elements in as they scroll into view (once). */
function reveals() {
  const els = document.querySelectorAll<HTMLElement>('[data-reveal]');
  if (reduced() || !('IntersectionObserver' in window)) {
    els.forEach((el) => el.classList.add('is-visible'));
    return;
  }
  // Masked headlines start fully clipped (clip-path), and browsers report a
  // fully clipped element as never intersecting, so it would never reveal.
  // Watch such elements through their parent instead.
  const masked = (el: HTMLElement) => el.matches('.display[data-reveal]');
  const owners = new Map<Element, HTMLElement[]>();
  const io = new IntersectionObserver(
    (entries) => {
      for (const e of entries) {
        if (!e.isIntersecting) continue;
        for (const el of owners.get(e.target) ?? []) el.classList.add('is-visible');
        io.unobserve(e.target);
      }
    },
    { rootMargin: '0px 0px -10% 0px', threshold: 0 },
  );
  els.forEach((el) => {
    const target = masked(el) && el.parentElement ? el.parentElement : el;
    owners.set(target, [...(owners.get(target) ?? []), el]);
    io.observe(target);
  });
}

/**
 * Scroll-scrubbed progress, written as --p (0→1):
 *  data-progress="sticky": progress through a tall section with a sticky stage
 *                          (dolly). 0 when its top hits the viewport top, 1 at
 *                          the end.
 *  data-progress="view":   0 as the element enters at the bottom, 1 as it
 *                          leaves at the top (word reveals, giant wordmark).
 * data-parallax="0.08" additionally gets --parallax in px.
 */
function scrollScrub() {
  const progress = [...document.querySelectorAll<HTMLElement>('[data-progress]')];
  const parallax = [...document.querySelectorAll<HTMLElement>('[data-parallax]')];
  if (reduced()) {
    // Show the finished state of every scrubbed effect.
    progress.forEach((el) => el.style.setProperty('--p', el.dataset.static ?? '1'));
    return;
  }
  let ticking = false;
  const update = () => {
    ticking = false;
    const vh = window.innerHeight;
    for (const el of progress) {
      const r = el.getBoundingClientRect();
      if (r.bottom < -vh || r.top > vh * 2) continue;
      const p =
        el.dataset.progress === 'sticky'
          ? clamp(-r.top / Math.max(1, r.height - vh))
          : clamp((vh - r.top) / (vh + r.height));
      el.style.setProperty('--p', p.toFixed(4));
    }
    for (const el of parallax) {
      const r = el.getBoundingClientRect();
      if (r.bottom < -200 || r.top > vh + 200) continue;
      const speed = Number(el.dataset.parallax) || 0.06;
      el.style.setProperty(
        '--parallax',
        `${((r.top + r.height / 2 - vh / 2) * -speed).toFixed(1)}px`,
      );
    }
  };
  const request = () => {
    if (!ticking) {
      ticking = true;
      requestAnimationFrame(update);
    }
  };
  addEventListener('scroll', request, { passive: true });
  addEventListener('resize', request, { passive: true });
  update();
}

/** Showcase: tabs switch the screen; a toggle switches light/dark. */
function showcase() {
  const root = document.querySelector<HTMLElement>('[data-showcase]');
  if (!root) return;
  const tabs = [...root.querySelectorAll<HTMLButtonElement>('[role="tab"]')];
  const panels = [...root.querySelectorAll<HTMLElement>('[data-screen]')];
  const captions = [...root.querySelectorAll<HTMLElement>('[data-caption]')];
  const toggle = root.querySelector<HTMLButtonElement>('[data-theme-toggle]');
  const tablist = root.querySelector<HTMLElement>('[role="tablist"]');
  const indicator = root.querySelector<HTMLElement>('.tabs__indicator');
  const stage = root.querySelector<HTMLElement>('.showcase__phone');
  let screen = tabs[0]?.dataset.tab ?? 'home';
  let theme: 'light' | 'dark' = 'light';
  const order = tabs.map((t) => t.dataset.tab!);

  /** Slide the pill under the selected tab, matching its width. */
  const moveIndicator = () => {
    const active = tabs.find((t) => t.dataset.tab === screen);
    if (!active || !indicator || !tablist) return;
    indicator.style.setProperty('--tab-x', `${active.offsetLeft}px`);
    indicator.style.setProperty('--tab-w', `${active.offsetWidth}px`);
  };

  /** dir: +1 / -1 slides the new screen in from that side; 0 crossfades. */
  const render = (dir = 0) => {
    // Commit the new direction before swapping classes, so the incoming
    // screen starts from the correct side instead of the old one.
    if (stage) {
      stage.style.setProperty('--dir', String(dir));
      void stage.offsetWidth;
    }
    for (const t of tabs) {
      const on = t.dataset.tab === screen;
      t.setAttribute('aria-selected', String(on));
      t.tabIndex = on ? 0 : -1;
    }
    for (const p of panels) {
      const on = p.dataset.screen === screen && p.dataset.theme === theme;
      const wasOn = p.classList.contains('is-active');
      if (wasOn && !on) {
        // Exit the opposite way, then drop back to the resting state.
        p.classList.add('is-leaving');
        window.setTimeout(() => p.classList.remove('is-leaving'), 650);
      }
      if (on) p.classList.remove('is-leaving');
      p.classList.toggle('is-active', on);
      p.setAttribute('aria-hidden', String(!on));
    }
    for (const c of captions) {
      const on = c.dataset.caption === screen;
      c.classList.toggle('is-active', on);
      c.setAttribute('aria-hidden', String(!on));
    }
    if (toggle) {
      toggle.setAttribute('aria-pressed', String(theme === 'dark'));
      toggle.querySelector('span')!.textContent = theme === 'dark' ? 'Dark' : 'Light';
    }
    moveIndicator();
  };

  tabs.forEach((t, i) => {
    t.addEventListener('click', () => {
      const next = t.dataset.tab!;
      if (next === screen) return;
      const dir = Math.sign(order.indexOf(next) - order.indexOf(screen));
      screen = next;
      render(reduced() ? 0 : dir);
    });
    t.addEventListener('keydown', (e) => {
      const dir = e.key === 'ArrowRight' ? 1 : e.key === 'ArrowLeft' ? -1 : 0;
      if (!dir) return;
      e.preventDefault();
      const next = tabs[(i + dir + tabs.length) % tabs.length];
      next.focus();
      next.click();
    });
  });
  toggle?.addEventListener('click', () => {
    theme = theme === 'light' ? 'dark' : 'light';
    render(0);
  });

  // Place the pill without animating, then let it glide from then on.
  render(0);
  if (indicator) {
    indicator.style.transition = 'none';
    moveIndicator();
    void indicator.offsetWidth;
    indicator.style.transition = '';
  }
  tablist?.classList.add('is-ready');
  addEventListener('resize', moveIndicator, { passive: true });
  // Web fonts change tab widths once loaded.
  void document.fonts?.ready.then(moveIndicator);
}

/** Header gains a backdrop once the page scrolls. */
function header() {
  const h = document.querySelector<HTMLElement>('[data-header]');
  if (!h) return;
  const set = () => h.classList.toggle('is-scrolled', scrollY > 12);
  addEventListener('scroll', set, { passive: true });
  set();
}

export function initMotion() {
  smoothScroll();
  reveals();
  scrollScrub();
  showcase();
  header();
}
