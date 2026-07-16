import { writable } from 'svelte/store';
import { hydrateFromServer, resetHydration } from './sync';

export interface User { id: number; username: string }

/** undefined = still checking, null = logged out, User = logged in */
export const currentUser = writable<User | null | undefined>(undefined);
export const authReady = writable(false);

/** Called once on app load — figures out if we already have a session. */
export async function initAuth(): Promise<void> {
  try {
    const res = await fetch('/api/me');
    if (res.ok) {
      const user = (await res.json()) as User;
      currentUser.set(user);
      await hydrateFromServer();
    } else {
      currentUser.set(null);
    }
  } catch {
    currentUser.set(null);
  } finally {
    authReady.set(true);
  }
}

async function post(path: string, body: unknown): Promise<Response> {
  return fetch(path, {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify(body)
  });
}

/** Returns an error message on failure, or null on success. */
export async function login(username: string, password: string): Promise<string | null> {
  const res = await post('/api/auth/login', { username, password });
  if (!res.ok) return (await res.json().catch(() => ({}))).message ?? 'Login failed';
  currentUser.set((await res.json()) as User);
  await hydrateFromServer();
  return null;
}

export async function register(username: string, password: string): Promise<string | null> {
  const res = await post('/api/auth/register', { username, password });
  if (!res.ok) return (await res.json().catch(() => ({}))).message ?? 'Could not sign up';
  currentUser.set((await res.json()) as User);
  await hydrateFromServer();
  return null;
}

export async function logout(): Promise<void> {
  await post('/api/auth/logout', {}).catch(() => {});
  resetHydration();
  currentUser.set(null);
  // Hard reload to drop the previous user's in-memory data cleanly.
  if (typeof location !== 'undefined') location.reload();
}
