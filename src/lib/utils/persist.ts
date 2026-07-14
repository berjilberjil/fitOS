import { writable, type Writable } from 'svelte/store';

const hasLS = () => typeof localStorage !== 'undefined';

export function persisted<T>(key: string, initial: T): Writable<T> {
  let start = initial;
  if (hasLS()) {
    const raw = localStorage.getItem(key);
    if (raw !== null) {
      try {
        start = JSON.parse(raw) as T;
      } catch {
        /* keep initial */
      }
    }
  }
  const store = writable<T>(start);
  if (hasLS()) {
    store.subscribe((value) => localStorage.setItem(key, JSON.stringify(value)));
  }
  return store;
}
