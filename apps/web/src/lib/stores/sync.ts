import { writable, type Writable } from 'svelte/store';

// Server-synced replacement for the old localStorage `persisted()`.
// Each store registers by key; on login we hydrate all of them from the
// server, and after that every change is debounced-pushed back to the server.

/* eslint-disable @typescript-eslint/no-explicit-any */
const registry = new Map<string, Writable<any>>();
const timers = new Map<string, ReturnType<typeof setTimeout>>();
let hydrated = false;
let serverState: Record<string, unknown> = {}; // cached server copy, so late-registered stores can seed from it

export function synced<T>(key: string, initial: T): Writable<T> {
  const store = writable<T>(initial);
  registry.set(key, store as Writable<any>);
  // If we already hydrated before this store registered (e.g. a tab opened
  // after login), seed it from the cached server copy BEFORE we subscribe —
  // otherwise it would push its empty default and clobber real server data.
  if (hydrated && key in serverState) {
    store.set(serverState[key] as T);
  }
  let first = true;
  store.subscribe((value) => {
    if (first) {
      first = false;
      return; // skip the initial emission
    }
    if (!hydrated) return; // don't push until we've loaded the server copy
    schedulePush(key, value);
  });
  return store;
}
/* eslint-enable @typescript-eslint/no-explicit-any */

function schedulePush(key: string, value: unknown): void {
  const prev = timers.get(key);
  if (prev) clearTimeout(prev);
  timers.set(
    key,
    setTimeout(() => {
      fetch(`/api/state/${encodeURIComponent(key)}`, {
        method: 'PUT',
        headers: { 'content-type': 'application/json' },
        body: JSON.stringify(value)
      }).catch(() => {
        /* offline — will re-push on next change */
      });
    }, 350)
  );
}

/** Load every registered store's value from the server (after login). */
export async function hydrateFromServer(): Promise<void> {
  const res = await fetch('/api/state');
  if (!res.ok) {
    // Do NOT enable push — empty defaults would clobber real server data.
    // Stores still work in-memory; next successful hydrate (or refresh) unlocks sync.
    hydrated = false;
    return;
  }
  serverState = (await res.json()) as Record<string, unknown>;

  // Sanitize body weight before stores seed — fixes corrupted 494 kg / BMI 171.
  const { sanitizeWeightLog } = await import('./weight-log');
  const { sanitizeProfile } = await import('./profile');
  let fixedProfile: unknown | null = null;
  let fixedWeightLog: unknown | null = null;
  if (serverState['luxifit.profile'] && typeof serverState['luxifit.profile'] === 'object') {
    const raw = serverState['luxifit.profile'] as import('$lib/types').Profile;
    const clean = sanitizeProfile(raw);
    if (
      clean.currentWeightKg !== raw.currentWeightKg ||
      clean.targetWeightKg !== raw.targetWeightKg
    ) {
      fixedProfile = clean;
      serverState['luxifit.profile'] = clean;
    }
  }
  if (serverState['luxifit.weightlog'] && typeof serverState['luxifit.weightlog'] === 'object') {
    const raw = serverState['luxifit.weightlog'] as Record<string, number>;
    const clean = sanitizeWeightLog(raw);
    if (Object.keys(clean).length !== Object.keys(raw).length ||
        Object.keys(raw).some((k) => clean[k] !== raw[k])) {
      fixedWeightLog = clean;
      serverState['luxifit.weightlog'] = clean;
    }
  }

  for (const [key, store] of registry) {
    if (key in serverState) store.set(serverState[key]);
  }
  hydrated = true; // set AFTER seeding so the seeding sets above don't push

  // Persist corrections so the bad values don't keep coming back.
  if (fixedProfile != null) schedulePush('luxifit.profile', fixedProfile);
  if (fixedWeightLog != null) schedulePush('luxifit.weightlog', fixedWeightLog);
}

export function resetHydration(): void {
  hydrated = false;
  serverState = {};
}

// Drop-in name so store files can keep calling `persisted(key, initial)`.
export { synced as persisted };
