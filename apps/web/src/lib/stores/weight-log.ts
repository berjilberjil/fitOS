import { persisted } from '$lib/stores/sync';
import { dateKey } from './log';

// date (YYYY-MM-DD) -> body weight in kg
export const weightLog = persisted<Record<string, number>>('luxifit.weightlog', {});

export function logWeight(kg: number, date = dateKey(new Date())): void {
  if (!(kg > 0)) return;
  // 2 decimals so ±0.25 kg steps stay exact (1-decimal rounding would turn 0.25 → 0.3)
  weightLog.update((m) => ({ ...m, [date]: Math.round(kg * 100) / 100 }));
}

export interface WeightPoint { date: string; kg: number }

/** Sorted oldest → newest. */
export function weightSeries(map: Record<string, number>): WeightPoint[] {
  return Object.keys(map)
    .sort()
    .map((date) => ({ date, kg: map[date] }));
}
