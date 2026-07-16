import { persisted } from '$lib/stores/sync';

export interface Settings {
  /** Google Gemini API key — kept on-device (localStorage) for client-side voice parsing. */
  geminiApiKey: string;
}

export const settings = persisted<Settings>('luxifit.settings', { geminiApiKey: '' });

export function setGeminiKey(key: string): void {
  settings.update((s) => ({ ...s, geminiApiKey: key.trim() }));
}

export function clearGeminiKey(): void {
  settings.update((s) => ({ ...s, geminiApiKey: '' }));
}
