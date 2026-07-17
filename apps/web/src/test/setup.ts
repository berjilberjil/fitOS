import { beforeEach } from 'vitest';

/** Minimal localStorage polyfill when jsdom/env leaves it undefined. */
function ensureLocalStorage(): void {
  try {
    if (typeof globalThis.localStorage !== 'undefined' && globalThis.localStorage?.clear) {
      return;
    }
  } catch {
    /* access can throw in some sandboxes */
  }
  const store = new Map<string, string>();
  const ls: Storage = {
    get length() {
      return store.size;
    },
    clear() {
      store.clear();
    },
    getItem(key: string) {
      return store.has(key) ? store.get(key)! : null;
    },
    setItem(key: string, value: string) {
      store.set(key, String(value));
    },
    removeItem(key: string) {
      store.delete(key);
    },
    key(index: number) {
      return [...store.keys()][index] ?? null;
    }
  };
  Object.defineProperty(globalThis, 'localStorage', {
    value: ls,
    writable: true,
    configurable: true
  });
}

ensureLocalStorage();

beforeEach(() => {
  ensureLocalStorage();
  localStorage.clear();
});
