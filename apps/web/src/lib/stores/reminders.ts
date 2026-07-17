import { browser } from '$app/environment';
import { writable } from 'svelte/store';

export type ReminderId =
  | 'morningLog'
  | 'breakfast'
  | 'lunch'
  | 'dinner'
  | 'gym'
  | 'rest';

export interface ReminderItem {
  id: ReminderId;
  title: string;
  body: string;
  enabled: boolean;
  /** "HH:MM" 24h */
  time: string;
}

export interface ReminderPrefs {
  masterEnabled: boolean;
  items: ReminderItem[];
}

const KEY = 'fitos.reminders';

export const DEFAULT_REMINDERS: ReminderItem[] = [
  {
    id: 'morningLog',
    title: 'Start your day',
    body: 'Open fitOS and log weight, meals, or plan today’s workout.',
    enabled: true,
    time: '05:00'
  },
  {
    id: 'breakfast',
    title: 'Breakfast time',
    body: 'Eat on time — log breakfast to stay on your calorie target.',
    enabled: true,
    time: '08:00'
  },
  {
    id: 'lunch',
    title: 'Lunch time',
    body: 'Lunch break — log your meal so Progress stays accurate.',
    enabled: true,
    time: '13:00'
  },
  {
    id: 'gym',
    title: 'Gym time',
    body: 'Time to train — open fitOS and crush today’s workout.',
    enabled: true,
    time: '16:30'
  },
  {
    id: 'dinner',
    title: 'Dinner time',
    body: 'Dinner time — fuel up and log it in fitOS.',
    enabled: true,
    time: '20:00'
  },
  {
    id: 'rest',
    title: 'Rest & recover',
    body: 'Recovery matters — rest, sleep, and stay hydrated.',
    enabled: true,
    time: '21:30'
  }
];

function load(): ReminderPrefs {
  if (!browser) return { masterEnabled: true, items: DEFAULT_REMINDERS.map((i) => ({ ...i })) };
  try {
    const raw = localStorage.getItem(KEY);
    if (!raw) return { masterEnabled: true, items: DEFAULT_REMINDERS.map((i) => ({ ...i })) };
    const parsed = JSON.parse(raw) as ReminderPrefs;
    // Merge defaults so new kinds appear after updates
    const byId = new Map(parsed.items?.map((i) => [i.id, i]) ?? []);
    const items = DEFAULT_REMINDERS.map((d) => {
      const prev = byId.get(d.id);
      return prev ? { ...d, ...prev, title: d.title, body: d.body } : { ...d };
    });
    return { masterEnabled: parsed.masterEnabled ?? true, items };
  } catch {
    return { masterEnabled: true, items: DEFAULT_REMINDERS.map((i) => ({ ...i })) };
  }
}

function save(p: ReminderPrefs) {
  if (!browser) return;
  localStorage.setItem(KEY, JSON.stringify(p));
}

export const reminders = writable<ReminderPrefs>(load());

if (browser) {
  reminders.subscribe(save);
}

export function setMaster(on: boolean) {
  reminders.update((p) => ({ ...p, masterEnabled: on }));
}

export function setReminderEnabled(id: ReminderId, enabled: boolean) {
  reminders.update((p) => ({
    ...p,
    items: p.items.map((i) => (i.id === id ? { ...i, enabled } : i))
  }));
}

export function setReminderTime(id: ReminderId, time: string) {
  reminders.update((p) => ({
    ...p,
    items: p.items.map((i) => (i.id === id ? { ...i, time } : i))
  }));
}

export function resetReminders() {
  reminders.set({ masterEnabled: true, items: DEFAULT_REMINDERS.map((i) => ({ ...i })) });
}

/** Best-effort browser permission (PWA). Native app uses UNUserNotificationCenter. */
export async function requestBrowserPermission(): Promise<NotificationPermission | 'unsupported'> {
  if (!browser || typeof Notification === 'undefined') return 'unsupported';
  if (Notification.permission === 'granted') return 'granted';
  return Notification.requestPermission();
}
