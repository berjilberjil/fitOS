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

// ---------------- Workout ----------------

export type WorkoutCategory =
  | 'chest' | 'back' | 'shoulders' | 'arms' | 'legs' | 'core' | 'cardio' | 'boxing';

export interface Exercise {
  id: string;
  name: string;
  icon: string;            // emoji, e.g. "🏋️"
  category: WorkoutCategory;
  equipment: string;       // "Barbell" | "Dumbbell" | "Machine" | "Cable" | "Bodyweight"
  primary: string;         // muscle worked, short label
  weighted: boolean;       // uses added load → shows the kg stepper (cardio/bodyweight = false)
  isDefault: boolean;
}

/** A planned exercise slot in a weekday routine. */
export interface PlanExercise { exerciseId: string; sets: number; reps: number; }
export interface WorkoutDayPlan { rest: boolean; items: PlanExercise[]; }
/** Weekly routine keyed by weekday 0 (Sun) .. 6 (Sat). */
export type WorkoutWeekPlan = Record<number, WorkoutDayPlan>;

/** What was actually trained on a date — carries the working weight for overload. */
export interface LoggedExercise {
  exerciseId: string;
  sets: number;
  reps: number;
  weightKg: number;        // working weight this session
  done: boolean;
}
export interface WorkoutDayLog { date: string; rest: boolean; items: LoggedExercise[]; }

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
