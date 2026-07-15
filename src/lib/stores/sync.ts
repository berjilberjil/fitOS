import { writable, type Writable } from 'svelte/store';

// Server-synced replacement for the old localStorage `persisted()`.
// Each store registers by key; on login we hydrate all of them from the
// server, and after that every change is debounced-pushed back to the server.

/* eslint-disable @typescript-eslint/no-explicit-any */
const registry = new Map<string, Writable<any>>();
const timers = new Map<string, ReturnType<typeof setTimeout>>();
let hydrated = false;

export function synced<T>(key: string, initial: T): Writable<T> {
  const store = writable<T>(initial);
  registry.set(key, store as Writable<any>);
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
  if (!res.ok) return;
  const data = (await res.json()) as Record<string, unknown>;
  for (const [key, store] of registry) {
    if (key in data) store.set(data[key]);
  }
  hydrated = true;
}

export function resetHydration(): void {
  hydrated = false;
}

// Drop-in name so store files can keep calling `persisted(key, initial)`.
export { synced as persisted };
