// Everything a maintainer may need to change lives here or in .env.
// Never put an invented link here: empty values render as "Coming soon".

const env = import.meta.env;
const clean = (v: string | undefined) => (v && v.trim() ? v.trim() : null);

export const site = {
  name: 'Poyshik',
  tagline: 'Every taka, accounted for.',
  description:
    'Poyshik is a calm daily expense tracker for Android. Log an expense in about three seconds, see what is safe to spend, and understand where your money goes. Works offline, no account, your data stays on your phone.',
  /** The app is Android-only today. */
  platform: 'Android',
  download: {
    /** Google Play listing, once published. */
    playStoreUrl: clean(env.PUBLIC_PLAY_STORE_URL),
    /** Direct APK (e.g. a GitHub release asset), if you choose to offer one. */
    apkUrl: clean(env.PUBLIC_APK_URL),
  },
  /**
   * Maker credit in the footer. The visible sign-off is the brush signature at
   * public/brand/rahat-signature.webp (transparent PNG/WebP, used as a mask so
   * it takes the brand colour); `name` is what screen readers announce.
   */
  creator: {
    name: 'Rahat Chowdhury',
    url: clean(env.PUBLIC_CREATOR_URL),
  },
  /** Optional; the footer hides the contact link when empty. */
  contactEmail: clean(env.PUBLIC_CONTACT_EMAIL),
  year: new Date().getFullYear(),
} as const;

export const downloadAvailable = Boolean(site.download.playStoreUrl || site.download.apkUrl);
