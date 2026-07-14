export type Sex = 'male' | 'female';
export type Category =
  | 'protein' | 'carb' | 'veg' | 'dairy' | 'fruit' | 'drink' | 'junk' | 'other';

export interface Macros {
  calories: number; // kcal
  protein: number;  // g
  carbs: number;    // g (total carbohydrate, fiber included)
  fiber: number;    // g
  fats: number;     // g
}

export interface Food {
  id: string;
  name: string;
  icon: string;         // emoji shown on the food, e.g. "🥚"
  category: Category;
  servingLabel: string; // e.g. "1 chapati", "1 cup", "100 g"
  perServing: Macros;
  vitamins?: string;    // informational only, never summed
  isJunk: boolean;
  isDefault: boolean;
}

export type MealKey = 'breakfast' | 'lunch' | 'dinner' | 'snacks';

export interface PlanItem { foodId: string; quantity: number; }
export type MealMap = Record<MealKey, PlanItem[]>;

/** The repeatable weekly routine, keyed by weekday 0 (Sun) .. 6 (Sat). */
export type WeekPlan = Record<number, MealMap>;

/** What was actually eaten on a date, grouped by meal. Macros are computed live. */
export interface DayLog { date: string; meals: MealMap; }

export interface Profile {
  name?: string;
  age: number;
  sex: Sex;
  heightCm: number;
  currentWeightKg: number;
  targetWeightKg: number;
  activity: number; // Mifflin activity factor
  onboarded: boolean;
}
