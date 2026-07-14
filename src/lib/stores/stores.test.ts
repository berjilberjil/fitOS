import { describe, it, expect, beforeEach } from 'vitest';
import { get } from 'svelte/store';
import { foods, addFood, updateFood, deleteFood } from './foods';
import { seedFoods } from '$lib/data/seed-foods';
import { weekPlan, addPlanFood } from './plan';
import {
  logMap, getOrSeedDay, bumpQty, swapFood, addFoodToMeal, removeFromMeal, weekdayOf
} from './log';
import { emptyMealMap } from '$lib/data/meals';
import type { WeekPlan } from '$lib/types';

function freshWeek(): WeekPlan {
  const w: WeekPlan = {};
  for (let d = 0; d < 7; d++) w[d] = emptyMealMap();
  return w;
}

beforeEach(() => {
  localStorage.clear();
  foods.set(seedFoods);
  weekPlan.set(freshWeek());
  logMap.set({});
});

describe('foods store', () => {
  it('seeds defaults with icons', () => {
    expect(get(foods).length).toBe(seedFoods.length);
    expect(get(foods)[0].icon.length).toBeGreaterThan(0);
  });
  it('adds, edits, deletes a user food', () => {
    const f = addFood({
      name: 'Test', icon: '🧪', category: 'other', servingLabel: '1',
      perServing: { calories: 10, protein: 1, carbs: 1, fiber: 0, fats: 0 },
      isJunk: false
    });
    expect(get(foods)[0].name).toBe('Test');
    expect(f.isDefault).toBe(false);
    updateFood({ ...f, name: 'Renamed' });
    expect(get(foods)[0].name).toBe('Renamed');
    deleteFood(f.id);
    expect(get(foods).find((x) => x.id === f.id)).toBeUndefined();
  });
  it('can edit a default food macros', () => {
    const seed = get(foods).find((x) => x.isDefault)!;
    updateFood({ ...seed, perServing: { ...seed.perServing, protein: 99 } });
    expect(get(foods).find((x) => x.id === seed.id)!.perServing.protein).toBe(99);
  });
});

describe('weekday plan', () => {
  it('adds a planned food to a weekday meal', () => {
    const idli = seedFoods.find((f) => f.name === 'Idli')!;
    addPlanFood(1 /* Mon */, 'breakfast', idli.id, 4);
    expect(get(weekPlan)[1].breakfast[0]).toEqual({ foodId: idli.id, quantity: 4 });
  });
});

describe('day log', () => {
  it('seeds a fresh day from the weekday routine (pre-logged as planned)', () => {
    const idli = seedFoods.find((f) => f.name === 'Idli')!;
    // 2026-07-13 is a Monday
    addPlanFood(weekdayOf('2026-07-13'), 'breakfast', idli.id, 4);
    const day = getOrSeedDay(get(logMap), '2026-07-13', get(weekPlan));
    expect(day.meals.breakfast[0]).toEqual({ foodId: idli.id, quantity: 4 });
  });
  it('bumps, swaps, adds and removes items', () => {
    const idli = seedFoods.find((f) => f.name === 'Idli')!;
    const dosa = seedFoods.find((f) => f.name === 'Plain dosa')!;
    const plan = get(weekPlan);
    addFoodToMeal('2026-07-13', 'lunch', idli.id, 1, plan);
    bumpQty('2026-07-13', 'lunch', 0, 2, plan);
    expect(getOrSeedDay(get(logMap), '2026-07-13', plan).meals.lunch[0].quantity).toBe(3);
    swapFood('2026-07-13', 'lunch', 0, dosa.id, plan);
    expect(getOrSeedDay(get(logMap), '2026-07-13', plan).meals.lunch[0].foodId).toBe(dosa.id);
    removeFromMeal('2026-07-13', 'lunch', 0, plan);
    expect(getOrSeedDay(get(logMap), '2026-07-13', plan).meals.lunch.length).toBe(0);
  });
  it('never drops quantity below zero', () => {
    const idli = seedFoods.find((f) => f.name === 'Idli')!;
    const plan = get(weekPlan);
    addFoodToMeal('2026-07-13', 'dinner', idli.id, 1, plan);
    bumpQty('2026-07-13', 'dinner', 0, -5, plan);
    expect(getOrSeedDay(get(logMap), '2026-07-13', plan).meals.dinner[0].quantity).toBe(0);
  });
});
