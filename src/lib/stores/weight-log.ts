import { persisted } from '$lib/stores/sync';
import { dateKey } from './log';

// date (YYYY-MM-DD) -> body weight in kg
export const weightLog = persisted<Record<string, number>>('luxifit.weightlog', {});

export function logWeight(kg: number, date = dateKey(new Date())): void {
  if (!(kg > 0)) return;
  weightLog.update((m) => ({ ...m, [date]: Math.round(kg * 10) / 10 }));
}

export interface WeightPoint { date: string; kg: number }

/** Sorted oldest → newest. */
export function weightSeries(map: Record<string, number>): WeightPoint[] {
  return Object.keys(map)
    .sort()
    .map((date) => ({ date, kg: map[date] }));
}
