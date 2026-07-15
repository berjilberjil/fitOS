import type { Macros, Sex } from '$lib/types';

export function round1(n: number): number {
  return Math.round(n * 10) / 10;
}

export function bmi(weightKg: number, heightCm: number): number {
  const m = heightCm / 100;
  return round1(weightKg / (m * m));
}

export type BmiStatus = 'underweight' | 'normal' | 'overweight' | 'obese';

export function bmiStatus(bmiValue: number): BmiStatus {
  if (bmiValue < 18.5) return 'underweight';
  if (bmiValue < 25) return 'normal';
  if (bmiValue < 30) return 'overweight';
  return 'obese';
}

export function targetBmi(targetWeightKg: number, heightCm: number): number {
  return bmi(targetWeightKg, heightCm);
}

export function bmr(sex: Sex, weightKg: number, heightCm: number, age: number): number {
  const base = 10 * weightKg + 6.25 * heightCm - 5 * age;
  return Math.round(base + (sex === 'male' ? 5 : -161));
}

export function tdee(bmrValue: number, activity: number): number {
  return Math.round(bmrValue * activity);
}

export function proteinGoal(weightKg: number): number {
  return Math.round(weightKg * 1.8);
}

// ---- body composition ----

/** Estimated body-fat % from BMI (Deurenberg). Rough, but good for tracking. */
export function bodyFat(bmiValue: number, age: number, sex: Sex): number {
  const s = sex === 'male' ? 1 : 0;
  return round1(Math.max(1.2 * bmiValue + 0.23 * age - 10.8 * s - 5.4, 3));
}

/** Body-fat % where abs typically become visible. */
export function sixPackBodyFat(sex: Sex): number {
  return sex === 'male' ? 10 : 19;
}

/** Goal weight to reach a target body-fat %, holding lean mass constant. */
export function weightAtBodyFat(currentKg: number, currentBF: number, targetBF: number): number {
  const lean = currentKg * (1 - currentBF / 100);
  return round1(lean / (1 - targetBF / 100));
}

/** Weeks to lose `kg` at a safe rate (default 0.5 kg/week). */
export function weeksToLose(kg: number, ratePerWeek = 0.5): number {
  return Math.max(Math.ceil(kg / ratePerWeek), 0);
}

export function caloriesFromMacros(
  m: Pick<Macros, 'protein' | 'carbs' | 'fiber' | 'fats'>
): number {
  const digestibleCarbs = Math.max(m.carbs - m.fiber, 0);
  return Math.round(m.protein * 4 + m.fats * 9 + digestibleCarbs * 4 + m.fiber * 2);
}

export function scaleMacros(m: Macros, quantity: number): Macros {
  return {
    calories: Math.round(m.calories * quantity),
    protein: round1(m.protein * quantity),
    carbs: round1(m.carbs * quantity),
    fiber: round1(m.fiber * quantity),
    fats: round1(m.fats * quantity)
  };
}

export function sumMacros(list: Macros[]): Macros {
  const total = list.reduce(
    (acc, m) => ({
      calories: acc.calories + m.calories,
      protein: acc.protein + m.protein,
      carbs: acc.carbs + m.carbs,
      fiber: acc.fiber + m.fiber,
      fats: acc.fats + m.fats
    }),
    { calories: 0, protein: 0, carbs: 0, fiber: 0, fats: 0 }
  );
  return {
    calories: Math.round(total.calories),
    protein: round1(total.protein),
    carbs: round1(total.carbs),
    fiber: round1(total.fiber),
    fats: round1(total.fats)
  };
}
