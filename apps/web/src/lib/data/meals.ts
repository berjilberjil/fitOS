import type { MealKey, MealMap } from '$lib/types';

export interface MealDef { key: MealKey; label: string; icon: string; }

export const MEALS: MealDef[] = [
  { key: 'breakfast', label: 'Breakfast', icon: '🌅' },
  { key: 'lunch', label: 'Lunch', icon: '☀️' },
  { key: 'dinner', label: 'Dinner', icon: '🌙' },
  { key: 'snacks', label: 'Snacks', icon: '🍿' }
];

export const MEAL_KEYS: MealKey[] = MEALS.map((m) => m.key);

export const WEEKDAYS = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
export const WEEKDAYS_LONG = [
  'Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'
];

export function emptyMealMap(): MealMap {
  return { breakfast: [], lunch: [], dinner: [], snacks: [] };
}
