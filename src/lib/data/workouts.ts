import type { WorkoutCategory, WorkoutDayPlan, WorkoutWeekPlan } from '$lib/types';

export interface CategoryDef { key: WorkoutCategory; label: string; icon: string; }

// Ordered push → pull → legs → core → cardio, each with its own icon.
export const WORKOUT_CATEGORIES: CategoryDef[] = [
  { key: 'chest', label: 'Chest', icon: '🛡️' },
  { key: 'back', label: 'Back', icon: '🪃' },
  { key: 'shoulders', label: 'Shoulders', icon: '🎯' },
  { key: 'arms', label: 'Arms', icon: '💪' },
  { key: 'legs', label: 'Legs', icon: '🦵' },
  { key: 'core', label: 'Core', icon: '🔥' },
  { key: 'cardio', label: 'Cardio', icon: '🏃' },
  { key: 'boxing', label: 'Boxing', icon: '🥊' }
];

export const CATEGORY_KEYS: WorkoutCategory[] = WORKOUT_CATEGORIES.map((c) => c.key);

export function categoryDef(key: WorkoutCategory): CategoryDef {
  return WORKOUT_CATEGORIES.find((c) => c.key === key) ?? WORKOUT_CATEGORIES[0];
}

export const DEFAULT_SETS = 3;
export const DEFAULT_REPS = 10;
export const WEIGHT_STEP = 0.5; // kg per +/- click — progressive overload

export function emptyWorkoutDay(): WorkoutDayPlan {
  return { rest: false, items: [] };
}

export function emptyWorkoutWeek(): WorkoutWeekPlan {
  const w: WorkoutWeekPlan = {};
  for (let d = 0; d < 7; d++) w[d] = emptyWorkoutDay();
  return w;
}
