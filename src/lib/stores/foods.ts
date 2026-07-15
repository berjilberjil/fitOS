import type { Food } from '$lib/types';
import { persisted } from '$lib/stores/sync';
import { newId } from '$lib/utils/id';
import { seedFoods } from '$lib/data/seed-foods';

export const foods = persisted<Food[]>('luxifit.foods', seedFoods);

export function addFood(input: Omit<Food, 'id' | 'isDefault'>): Food {
  const food: Food = { ...input, id: newId(), isDefault: false };
  foods.update((list) => [food, ...list]);
  return food;
}

export function updateFood(f: Food): void {
  foods.update((list) => list.map((x) => (x.id === f.id ? f : x)));
}

export function deleteFood(id: string): void {
  foods.update((list) => list.filter((x) => x.id !== id));
}

export function findFood(list: Food[], id: string): Food | undefined {
  return list.find((x) => x.id === id);
}
