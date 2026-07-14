import { describe, it, expect, beforeEach } from 'vitest';
import { get } from 'svelte/store';
import { foods, addFood, updateFood, deleteFood } from './foods';
import { seedFoods } from '$lib/data/seed-foods';
import {
  logMap, addLogItem, removeLogItem, logItemFromFood, applyPlanToDay, getDay
} from './log';
import { addPlan } from './plans';

beforeEach(() => {
  localStorage.clear();
  foods.set(seedFoods);
  logMap.set({});
});

describe('foods store', () => {
  it('seeds defaults', () => {
    expect(get(foods).length).toBe(seedFoods.length);
  });
  it('adds a user food at the front, editable and deletable', () => {
    const f = addFood({
      name: 'Test', category: 'other', servingLabel: '1',
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
  it('can edit a default food', () => {
    const seed = get(foods).find((x) => x.isDefault)!;
    updateFood({ ...seed, name: 'Edited default' });
    expect(get(foods).find((x) => x.id === seed.id)!.name).toBe('Edited default');
  });
});

describe('log store', () => {
  it('adds and removes items for a date, snapshotting macros', () => {
    const chapati = seedFoods.find((f) => f.name === 'Chapati')!;
    addLogItem('2026-07-14', logItemFromFood(chapati, 3));
    const day = getDay(get(logMap), '2026-07-14');
    expect(day.items.length).toBe(1);
    expect(day.items[0].macros.calories).toBe(312);
    removeLogItem('2026-07-14', 0);
    expect(getDay(get(logMap), '2026-07-14').items.length).toBe(0);
  });
  it('applies a plan into the day log', () => {
    const idli = seedFoods.find((f) => f.name === 'Idli')!;
    const plan = addPlan('Breakfast', [{ foodId: idli.id, quantity: 4 }]);
    applyPlanToDay('2026-07-14', plan, seedFoods);
    const day = getDay(get(logMap), '2026-07-14');
    expect(day.items[0].macros.calories).toBe(232);
  });
});
