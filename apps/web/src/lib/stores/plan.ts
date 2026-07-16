import type { WeekPlan, MealKey } from '$lib/types';
import { persisted } from '$lib/stores/sync';
import { emptyMealMap } from '$lib/data/meals';

function emptyWeek(): WeekPlan {
  const w: WeekPlan = {};
  for (let d = 0; d < 7; d++) w[d] = emptyMealMap();
  return w;
}

export const weekPlan = persisted<WeekPlan>('luxifit.weekplan', emptyWeek());

/** Guard against older/partial persisted shapes. */
function ensureDay(w: WeekPlan, weekday: number): WeekPlan {
  if (!w[weekday]) w[weekday] = emptyMealMap();
  if (!w[weekday].breakfast) w[weekday] = { ...emptyMealMap(), ...w[weekday] };
  return w;
}

export function addPlanFood(weekday: number, meal: MealKey, foodId: string, quantity = 1): void {
  weekPlan.update((w) => {
    const next = ensureDay({ ...w }, weekday);
    const day = { ...next[weekday], [meal]: [...next[weekday][meal], { foodId, quantity }] };
    return { ...next, [weekday]: day };
  });
}

export function setPlanQty(weekday: number, meal: MealKey, index: number, quantity: number): void {
  weekPlan.update((w) => {
    const next = ensureDay({ ...w }, weekday);
    const items = next[weekday][meal].map((it, i) =>
      i === index ? { ...it, quantity: Math.max(quantity, 0) } : it
    );
    return { ...next, [weekday]: { ...next[weekday], [meal]: items } };
  });
}

export function swapPlanFood(weekday: number, meal: MealKey, index: number, foodId: string): void {
  weekPlan.update((w) => {
    const next = ensureDay({ ...w }, weekday);
    const items = next[weekday][meal].map((it, i) => (i === index ? { ...it, foodId } : it));
    return { ...next, [weekday]: { ...next[weekday], [meal]: items } };
  });
}

export function removePlanFood(weekday: number, meal: MealKey, index: number): void {
  weekPlan.update((w) => {
    const next = ensureDay({ ...w }, weekday);
    const items = next[weekday][meal].filter((_, i) => i !== index);
    return { ...next, [weekday]: { ...next[weekday], [meal]: items } };
  });
}

/** Copy one weekday's whole routine onto another weekday. */
export function copyDayPlan(from: number, to: number): void {
  weekPlan.update((w) => {
    const next = ensureDay(ensureDay({ ...w }, from), to);
    const clone = emptyMealMap();
    (Object.keys(clone) as MealKey[]).forEach((k) => {
      clone[k] = next[from][k].map((it) => ({ ...it }));
    });
    return { ...next, [to]: clone };
  });
}
