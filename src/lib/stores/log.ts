import type { DayLog, DietPlan, Food, LogItem } from '$lib/types';
import { persisted } from '$lib/utils/persist';
import { scaleMacros } from '$lib/utils/nutrition';
import { findFood } from './foods';

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

export function getDay(map: Record<string, DayLog>, date: string): DayLog {
  return map[date] ?? { date, items: [] };
}

export function logItemFromFood(food: Food, quantity: number): LogItem {
  return {
    foodId: food.id,
    name: food.name,
    quantity,
    macros: scaleMacros(food.perServing, quantity)
  };
}

export function addLogItem(date: string, item: LogItem): void {
  logMap.update((map) => {
    const day = getDay(map, date);
    return { ...map, [date]: { date, items: [...day.items, item] } };
  });
}

export function removeLogItem(date: string, index: number): void {
  logMap.update((map) => {
    const day = getDay(map, date);
    const items = day.items.filter((_, i) => i !== index);
    return { ...map, [date]: { date, items } };
  });
}

export function applyPlanToDay(date: string, plan: DietPlan, foods: Food[]): void {
  const items = plan.items
    .map((pi) => {
      const food = findFood(foods, pi.foodId);
      return food ? logItemFromFood(food, pi.quantity) : null;
    })
    .filter((x): x is LogItem => x !== null);
  logMap.update((map) => {
    const day = getDay(map, date);
    return { ...map, [date]: { date, items: [...day.items, ...items] } };
  });
}
