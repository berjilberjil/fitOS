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
  for (const [key, store] of registry) {
    if (key in serverState) store.set(serverState[key]);
  }
  hydrated = true; // set AFTER seeding so the seeding sets above don't push
}

export function resetHydration(): void {
  hydrated = false;
  serverState = {};
}

// Drop-in name so store files can keep calling `persisted(key, initial)`.
export { synced as persisted };
