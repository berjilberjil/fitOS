import { describe, it, expect } from 'vitest';
import {
  bmi, bmiStatus, targetBmi, bmr, tdee, proteinGoal,
  caloriesFromMacros, scaleMacros, sumMacros
} from './nutrition';
import type { Macros } from '$lib/types';

describe('bmi', () => {
  it('computes kg / m^2 to one decimal', () => {
    expect(bmi(70, 175)).toBe(22.9);
  });
});

describe('bmiStatus', () => {
  it('classifies bands', () => {
    expect(bmiStatus(17)).toBe('underweight');
    expect(bmiStatus(22)).toBe('normal');
    expect(bmiStatus(27)).toBe('overweight');
    expect(bmiStatus(31)).toBe('obese');
    expect(bmiStatus(18.5)).toBe('normal');
    expect(bmiStatus(25)).toBe('overweight');
  });
});

describe('targetBmi', () => {
  it('is bmi at the target weight', () => {
    expect(targetBmi(65, 175)).toBe(21.2);
  });
});

describe('bmr (Mifflin-St Jeor)', () => {
  it('male', () => {
    expect(bmr('male', 70, 175, 21)).toBe(1649);
  });
  it('female', () => {
    expect(bmr('female', 60, 165, 25)).toBe(1345);
  });
});

describe('tdee', () => {
  it('multiplies bmr by activity, rounded', () => {
    expect(tdee(1649, 1.375)).toBe(2267);
  });
});

describe('proteinGoal', () => {
  it('is 1.8 g/kg rounded', () => {
    expect(proteinGoal(70)).toBe(126);
  });
});

describe('caloriesFromMacros', () => {
  it('subtracts fiber from carbs to avoid double count', () => {
    expect(caloriesFromMacros({ protein: 3, carbs: 18, fiber: 2.7, fats: 2.5 })).toBe(101);
  });
  it('clamps digestible carbs at 0 when fiber exceeds carbs', () => {
    expect(caloriesFromMacros({ protein: 0, carbs: 2, fiber: 5, fats: 0 })).toBe(10);
  });
});

describe('scaleMacros', () => {
  it('scales every field by quantity', () => {
    const m: Macros = { calories: 100, protein: 3, carbs: 18, fiber: 2, fats: 2.5 };
    expect(scaleMacros(m, 2)).toEqual({ calories: 200, protein: 6, carbs: 36, fiber: 4, fats: 5 });
  });
  it('supports fractional quantity', () => {
    const m: Macros = { calories: 100, protein: 3, carbs: 18, fiber: 2, fats: 2.5 };
    expect(scaleMacros(m, 0.5)).toEqual({ calories: 50, protein: 1.5, carbs: 9, fiber: 1, fats: 1.25 });
  });
});

describe('sumMacros', () => {
  it('adds a list field-wise', () => {
    const a: Macros = { calories: 100, protein: 3, carbs: 18, fiber: 2, fats: 2.5 };
    const b: Macros = { calories: 50, protein: 1.5, carbs: 9, fiber: 1, fats: 1.25 };
    expect(sumMacros([a, b])).toEqual({ calories: 150, protein: 4.5, carbs: 27, fiber: 3, fats: 3.75 });
  });
  it('returns zeros for empty list', () => {
    expect(sumMacros([])).toEqual({ calories: 0, protein: 0, carbs: 0, fiber: 0, fats: 0 });
  });
});
