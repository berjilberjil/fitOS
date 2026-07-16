import { describe, it, expect } from 'vitest';
import { seedFoods } from './seed-foods';

describe('seedFoods', () => {
  it('has at least 45 foods', () => {
    expect(seedFoods.length).toBeGreaterThanOrEqual(45);
  });
  it('has unique ids all prefixed seed-', () => {
    const ids = seedFoods.map((f) => f.id);
    expect(new Set(ids).size).toBe(ids.length);
    expect(ids.every((id) => id.startsWith('seed-'))).toBe(true);
  });
  it('marks every seed as default with non-negative macros', () => {
    for (const f of seedFoods) {
      expect(f.isDefault).toBe(true);
      const m = f.perServing;
      for (const v of [m.calories, m.protein, m.carbs, m.fiber, m.fats]) {
        expect(v).toBeGreaterThanOrEqual(0);
      }
      expect(f.servingLabel.length).toBeGreaterThan(0);
    }
  });
  it('includes at least 6 junk items', () => {
    expect(seedFoods.filter((f) => f.isJunk).length).toBeGreaterThanOrEqual(6);
  });
});
