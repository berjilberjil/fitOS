import { persisted } from '$lib/stores/sync';
import { dateKey } from './log';

/** Plausible adult body weight (kg). Prevents runaway ± steppers (e.g. 494 kg). */
export const BODY_WEIGHT_MIN_KG = 30;
export const BODY_WEIGHT_MAX_KG = 250;

export function isPlausibleBodyWeight(kg: number): boolean {
  return Number.isFinite(kg) && kg >= BODY_WEIGHT_MIN_KG && kg <= BODY_WEIGHT_MAX_KG;
}

export function clampBodyWeight(kg: number): number {
  const c = Math.min(Math.max(kg, BODY_WEIGHT_MIN_KG), BODY_WEIGHT_MAX_KG);
  return Math.round(c * 100) / 100;
}

/** Drop impossible entries (e.g. corrupted 494 kg) so charts/BMI stay sane. */
export function sanitizeWeightLog(map: Record<string, number>): Record<string, number> {
  const out: Record<string, number> = {};
  for (const [date, kg] of Object.entries(map)) {
    if (isPlausibleBodyWeight(kg)) out[date] = Math.round(kg * 100) / 100;
  }
  return out;
}

// date (YYYY-MM-DD) -> body weight in kg
export const weightLog = persisted<Record<string, number>>('luxifit.weightlog', {});

export function logWeight(kg: number, date = dateKey(new Date())): void {
  if (!Number.isFinite(kg) || kg <= 0) return;
  const clamped = clampBodyWeight(kg);
  // 2 decimals so ±0.25 kg steps stay exact (1-decimal rounding would turn 0.25 → 0.3)
  weightLog.update((m) => ({ ...m, [date]: clamped }));
}

export interface WeightPoint { date: string; kg: number }

/** Sorted oldest → newest (impossible weights already filtered if sanitized). */
export function weightSeries(map: Record<string, number>): WeightPoint[] {
  return Object.keys(map)
    .sort()
    .filter((date) => isPlausibleBodyWeight(map[date]))
    .map((date) => ({ date, kg: map[date] }));
}
