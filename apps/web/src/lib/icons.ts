// Central emoji→icon mapping. Real SVG icons (Iconify: lucide + game-icons),
// no emojis anywhere in the UI.

export const navIcons: Record<string, string> = {
  '/food': 'lucide:utensils',
  '/progress': 'lucide:trending-up',
  '/workout': 'lucide:dumbbell',
  '/anatomy': 'game-icons:muscle-up',
  '/profile': 'lucide:user'
};

export const mealIcons: Record<string, string> = {
  breakfast: 'lucide:sunrise',
  lunch: 'lucide:sun',
  dinner: 'lucide:moon',
  snacks: 'lucide:cookie'
};

export const workoutCatIcons: Record<string, string> = {
  chest: 'game-icons:chest',
  back: 'game-icons:body-balance',
  shoulders: 'game-icons:shoulder-armor',
  arms: 'game-icons:biceps',
  legs: 'game-icons:leg',
  core: 'game-icons:abdominal-armor',
  cardio: 'lucide:heart-pulse',
  boxing: 'game-icons:boxing-glove'
};

export const muscleIcons: Record<string, string> = {
  shoulders: 'game-icons:shoulder-armor',
  chest: 'game-icons:chest',
  back: 'game-icons:body-balance',
  biceps: 'game-icons:biceps',
  triceps: 'game-icons:arm-bandage',
  forearms: 'lucide:hand',
  core: 'game-icons:abdominal-armor',
  glutes: 'game-icons:leg',
  quads: 'game-icons:leg',
  hamstrings: 'game-icons:leg',
  calves: 'lucide:footprints'
};

export const FOOD_FALLBACK = 'lucide:utensils';
export const EXERCISE_FALLBACK = 'lucide:dumbbell';
export const MIC_ICON = 'lucide:mic';
export const REST_ICON = 'lucide:moon';
export const PROGRESS_ICON = 'lucide:trending-up';

export const navIcon = (href: string) => navIcons[href] ?? 'lucide:circle';
export const mealIcon = (key: string) => mealIcons[key] ?? 'lucide:utensils';
export const workoutCatIcon = (key: string) => workoutCatIcons[key] ?? 'lucide:dumbbell';
export const muscleIcon = (id: string) => muscleIcons[id] ?? 'game-icons:muscle-up';
