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
  category: Category;
  servingLabel: string; // e.g. "1 chapati", "1 cup", "100 g"
  perServing: Macros;
  vitamins?: string;    // informational only, never summed
  isJunk: boolean;
  isDefault: boolean;
}

export interface PlanItem { foodId: string; quantity: number; }
export interface DietPlan { id: string; name: string; items: PlanItem[]; }

export interface LogItem {
  foodId: string;
  name: string;
  quantity: number;
  macros: Macros; // snapshot of scaled macros at log time
}
export interface DayLog { date: string; items: LogItem[]; } // date = YYYY-MM-DD

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
