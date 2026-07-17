import { browser } from '$app/environment';
import { writable } from 'svelte/store';

export type ThemeMode = 'system' | 'light' | 'dark';

const KEY = 'fitos.theme';

function readInitial(): ThemeMode {
  if (!browser) return 'system';
  const raw = localStorage.getItem(KEY);
  if (raw === 'light' || raw === 'dark' || raw === 'system') return raw;
  return 'system';
}

function applyTheme(mode: ThemeMode): void {
  if (!browser) return;
  document.documentElement.setAttribute('data-theme', mode);
}

export const theme = writable<ThemeMode>(readInitial());

if (browser) {
  applyTheme(readInitial());
  theme.subscribe((mode) => {
    localStorage.setItem(KEY, mode);
    applyTheme(mode);
  });
}

export function setTheme(mode: ThemeMode): void {
  theme.set(mode);
}
