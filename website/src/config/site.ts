// Everything a maintainer may need to change lives here or in .env.
// Never put an invented link here: empty values render as "Coming soon".

const env = import.meta.env;
const clean = (v: string | undefined) => (v && v.trim() ? v.trim() : null);

export const site = {
  name: 'Poyshik',
  tagline: 'Every taka, accounted for.',
  description:
    'Poyshik is a calm daily expense tracker for Android. Log an expense in about three seconds, see what is safe to spend, and understand where your money goes. Works offline, in English or Bangla, no account, your data stays on your phone.',
  /** The app is Android-only today. */
  platform: 'Android',
  download: {
    /** Google Play listing, once published. */
    playStoreUrl: clean(env.PUBLIC_PLAY_STORE_URL),
    /** Direct APK (e.g. a GitHub release asset), if you choose to offer one.
     *  The universal APK: runs on every Android phone, but is the largest. */
    apkUrl: clean(env.PUBLIC_APK_URL),
    /** Smaller APK for 64-bit ARM phones (nearly every phone since ~2017).
     *  When set, it becomes the main download and the universal APK is
     *  offered as a fallback link. */
    apkArm64Url: clean(env.PUBLIC_APK_ARM64_URL),
    /** Shown next to a direct APK download, e.g. "1.1.0". */
    apkVersion: clean(env.PUBLIC_APK_VERSION),
    /** Lowest Android version the app installs on (minSdk 24). */
    minAndroid: '7.0',
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

export const downloadAvailable = Boolean(
  site.download.playStoreUrl || site.download.apkArm64Url || site.download.apkUrl,
);
