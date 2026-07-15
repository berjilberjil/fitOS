import type { DayLog, MealKey, MealMap, WeekPlan } from '$lib/types';
import { persisted } from '$lib/stores/sync';
import { emptyMealMap } from '$lib/data/meals';

export const logMap = persisted<Record<string, DayLog>>('luxifit.log', {});

export function dateKey(d: Date): string {
  const y = d.getFullYear();
  const m = String(d.getMonth() + 1).padStart(2, '0');
  const day = String(d.getDate()).padStart(2, '0');
  return `${y}-${m}-${day}`;
}

export function todayKey(): string {
  return dateKey(new Date());
}

export function weekdayOf(dateStr: string): number {
  const [y, m, d] = dateStr.split('-').map(Number);
  return new Date(y, m - 1, d).getDay();
}

function normalizeMeals(meals?: Partial<MealMap>): MealMap {
  return { ...emptyMealMap(), ...(meals ?? {}) };
}

/**
 * Return the day's log, seeding it from the weekday routine the first time a
 * date is opened. Planned quantities become the starting eaten quantities, so
 * the day opens pre-logged as planned — you only touch the deviations.
 */
export function getOrSeedDay(map: Record<string, DayLog>, date: string, plan: WeekPlan): DayLog {
  const existing = map[date];
  if (existing) return { date, meals: normalizeMeals(existing.meals) };
  const routine = plan[weekdayOf(date)];
  const meals = emptyMealMap();
  if (routine) {
    (Object.keys(meals) as MealKey[]).forEach((k) => {
      meals[k] = (routine[k] ?? []).map((it) => ({ ...it }));
    });
  }
  return { date, meals };
}

function write(date: string, meals: MealMap): void {
  logMap.update((map) => ({ ...map, [date]: { date, meals } }));
}

export function ensureDay(date: string, plan: WeekPlan): void {
  logMap.update((map) => {
    if (map[date]) return map;
    return { ...map, [date]: getOrSeedDay(map, date, plan) };
  });
}

export function bumpQty(date: string, meal: MealKey, index: number, delta: number, plan: WeekPlan): void {
  logMap.update((map) => {
    const day = getOrSeedDay(map, date, plan);
    const items = day.meals[meal].map((it, i) =>
      i === index ? { ...it, quantity: Math.max(Math.round((it.quantity + delta) * 100) / 100, 0) } : it
    );
    return { ...map, [date]: { date, meals: { ...day.meals, [meal]: items } } };
  });
}

export function setQty(date: string, meal: MealKey, index: number, quantity: number, plan: WeekPlan): void {
  logMap.update((map) => {
    const day = getOrSeedDay(map, date, plan);
    const items = day.meals[meal].map((it, i) =>
      i === index ? { ...it, quantity: Math.max(quantity, 0) } : it
    );
    return { ...map, [date]: { date, meals: { ...day.meals, [meal]: items } } };
  });
}

export function swapFood(date: string, meal: MealKey, index: number, foodId: string, plan: WeekPlan): void {
  logMap.update((map) => {
    const day = getOrSeedDay(map, date, plan);
    const items = day.meals[meal].map((it, i) => (i === index ? { ...it, foodId } : it));
    return { ...map, [date]: { date, meals: { ...day.meals, [meal]: items } } };
  });
}

export function addFoodToMeal(date: string, meal: MealKey, foodId: string, quantity: number, plan: WeekPlan): void {
  logMap.update((map) => {
    const day = getOrSeedDay(map, date, plan);
    const items = [...day.meals[meal], { foodId, quantity }];
    return { ...map, [date]: { date, meals: { ...day.meals, [meal]: items } } };
  });
}

export function removeFromMeal(date: string, meal: MealKey, index: number, plan: WeekPlan): void {
  logMap.update((map) => {
    const day = getOrSeedDay(map, date, plan);
    const items = day.meals[meal].filter((_, i) => i !== index);
    return { ...map, [date]: { date, meals: { ...day.meals, [meal]: items } } };
  });
}
