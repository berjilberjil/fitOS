import type { Exercise, WorkoutCategory } from '$lib/types';

// [name, icon, category, equipment, primary muscle, weighted?]
// weighted=false → bodyweight / cardio (no kg stepper). Defaults to true.
type Seed = [string, string, WorkoutCategory, string, string, boolean?];

const rows: Seed[] = [
  // ---- Chest ----
  ['Barbell bench press', '🏋️', 'chest', 'Barbell', 'Mid chest'],
  ['Incline dumbbell press', '🏋️', 'chest', 'Dumbbell', 'Upper chest'],
  ['Machine chest press', '⚙️', 'chest', 'Machine', 'Chest'],
  ['Cable crossover', '🕸️', 'chest', 'Cable', 'Inner chest'],
  ['Pec deck fly', '🦋', 'chest', 'Machine', 'Chest'],
  ['Chest dip', '🤸', 'chest', 'Bodyweight', 'Lower chest'],
  ['Push-up', '🤸', 'chest', 'Bodyweight', 'Chest', false],

  // ---- Back ----
  ['Deadlift', '🏋️', 'back', 'Barbell', 'Whole back'],
  ['Pull-up', '🧗', 'back', 'Bodyweight', 'Lats'],
  ['Lat pulldown', '🪝', 'back', 'Cable', 'Lats'],
  ['Barbell row', '🏋️', 'back', 'Barbell', 'Mid back'],
  ['Seated cable row', '🚣', 'back', 'Cable', 'Mid back'],
  ['One-arm dumbbell row', '🏋️', 'back', 'Dumbbell', 'Lats'],
  ['Face pull', '🎣', 'back', 'Cable', 'Rear delts'],

  // ---- Shoulders ----
  ['Overhead press', '🏋️', 'shoulders', 'Barbell', 'Front delts'],
  ['Dumbbell shoulder press', '🏋️', 'shoulders', 'Dumbbell', 'Shoulders'],
  ['Lateral raise', '↔️', 'shoulders', 'Dumbbell', 'Side delts'],
  ['Front raise', '⬆️', 'shoulders', 'Dumbbell', 'Front delts'],
  ['Reverse pec deck', '🦋', 'shoulders', 'Machine', 'Rear delts'],
  ['Barbell shrug', '🤷', 'shoulders', 'Barbell', 'Traps'],

  // ---- Arms ----
  ['Barbell curl', '💪', 'arms', 'Barbell', 'Biceps'],
  ['Dumbbell curl', '💪', 'arms', 'Dumbbell', 'Biceps'],
  ['Hammer curl', '🔨', 'arms', 'Dumbbell', 'Brachialis'],
  ['Preacher curl', '💺', 'arms', 'Machine', 'Biceps'],
  ['Triceps pushdown', '⬇️', 'arms', 'Cable', 'Triceps'],
  ['Overhead triceps extension', '🔺', 'arms', 'Dumbbell', 'Triceps'],
  ['Close-grip bench press', '🏋️', 'arms', 'Barbell', 'Triceps'],
  ['Skull crusher', '💀', 'arms', 'Barbell', 'Triceps'],

  // ---- Legs ----
  ['Barbell squat', '🏋️', 'legs', 'Barbell', 'Quads'],
  ['Leg press', '🦵', 'legs', 'Machine', 'Quads'],
  ['Romanian deadlift', '🏋️', 'legs', 'Barbell', 'Hamstrings'],
  ['Leg extension', '🦿', 'legs', 'Machine', 'Quads'],
  ['Lying leg curl', '🦵', 'legs', 'Machine', 'Hamstrings'],
  ['Walking lunge', '🚶', 'legs', 'Dumbbell', 'Quads / glutes'],
  ['Bulgarian split squat', '🦵', 'legs', 'Dumbbell', 'Quads / glutes'],
  ['Hip thrust', '🍑', 'legs', 'Barbell', 'Glutes'],
  ['Standing calf raise', '🦶', 'legs', 'Machine', 'Calves'],

  // ---- Core ----
  ['Plank', '🧘', 'core', 'Bodyweight', 'Whole core', false],
  ['Hanging leg raise', '🧗', 'core', 'Bodyweight', 'Lower abs', false],
  ['Cable crunch', '🔗', 'core', 'Cable', 'Abs'],
  ['Russian twist', '🔄', 'core', 'Bodyweight', 'Obliques'],
  ['Ab wheel rollout', '🎡', 'core', 'Bodyweight', 'Whole core', false],

  // ---- Cardio ----
  ['Treadmill run', '🏃', 'cardio', 'Cardio', 'Heart / legs', false],
  ['Incline walk', '🚶', 'cardio', 'Cardio', 'Heart', false],
  ['Cycling', '🚴', 'cardio', 'Cardio', 'Legs', false],
  ['Rowing machine', '🚣', 'cardio', 'Cardio', 'Full body', false],
  ['Jump rope', '🪢', 'cardio', 'Cardio', 'Heart / calves', false],
  ['Stair climber', '🪜', 'cardio', 'Cardio', 'Legs', false],

  // ---- Chest (more) ----
  ['Incline barbell press', '🏋️', 'chest', 'Barbell', 'Upper chest'],
  ['Decline bench press', '🏋️', 'chest', 'Barbell', 'Lower chest'],
  ['Dumbbell fly', '🦋', 'chest', 'Dumbbell', 'Chest'],

  // ---- Back (more) ----
  ['T-bar row', '🏋️', 'back', 'Barbell', 'Mid back'],
  ['Chin-up', '🧗', 'back', 'Bodyweight', 'Lats / biceps'],
  ['Back extension', '🧎', 'back', 'Bodyweight', 'Lower back', false],
  ['Straight-arm pulldown', '🪝', 'back', 'Cable', 'Lats'],

  // ---- Shoulders (more) ----
  ['Arnold press', '🏋️', 'shoulders', 'Dumbbell', 'Shoulders'],
  ['Upright row', '🏋️', 'shoulders', 'Barbell', 'Side delts / traps'],
  ['Cable lateral raise', '↔️', 'shoulders', 'Cable', 'Side delts'],

  // ---- Arms (more) ----
  ['Concentration curl', '💪', 'arms', 'Dumbbell', 'Biceps'],
  ['Cable bicep curl', '🔗', 'arms', 'Cable', 'Biceps'],
  ['EZ-bar curl', '💪', 'arms', 'Barbell', 'Biceps'],
  ['Bench dip', '🪑', 'arms', 'Bodyweight', 'Triceps', false],

  // ---- Legs (more) ----
  ['Front squat', '🏋️', 'legs', 'Barbell', 'Quads'],
  ['Hack squat', '🦵', 'legs', 'Machine', 'Quads'],
  ['Goblet squat', '🏋️', 'legs', 'Dumbbell', 'Quads'],
  ['Step-up', '🪜', 'legs', 'Dumbbell', 'Quads / glutes'],
  ['Seated leg curl', '🦵', 'legs', 'Machine', 'Hamstrings'],
  ['Seated calf raise', '🦶', 'legs', 'Machine', 'Calves'],

  // ---- Core (more) ----
  ['Crunch', '🧎', 'core', 'Bodyweight', 'Abs', false],
  ['Bicycle crunch', '🚲', 'core', 'Bodyweight', 'Abs / obliques', false],
  ['Mountain climber', '⛰️', 'core', 'Bodyweight', 'Whole core', false],
  ['Lying leg raise', '🦵', 'core', 'Bodyweight', 'Lower abs', false],
  ['Side plank', '🧘', 'core', 'Bodyweight', 'Obliques', false],

  // ---- Cardio (more) ----
  ['Elliptical', '🏃', 'cardio', 'Cardio', 'Full body', false],
  ['Battle rope', '🪢', 'cardio', 'Cardio', 'Full body', false],
  ['Burpee', '🤸', 'cardio', 'Bodyweight', 'Full body', false],

  // ---- Boxing (heavy bag) ----
  ['Jab', '🥊', 'boxing', 'Bag', 'Shoulders / core', false],
  ['Cross', '🥊', 'boxing', 'Bag', 'Shoulders / core', false],
  ['Hook', '🥊', 'boxing', 'Bag', 'Shoulders / obliques', false],
  ['Uppercut', '🥊', 'boxing', 'Bag', 'Arms / core', false],
  ['Jab-cross combo', '🥊', 'boxing', 'Bag', 'Full body', false],
  ['Heavy bag round', '🥊', 'boxing', 'Bag', 'Full body / cardio', false],
  ['Speed bag', '🥊', 'boxing', 'Bag', 'Shoulders / timing', false]
];

export const seedExercises: Exercise[] = rows.map(
  ([name, icon, category, equipment, primary, weighted], i) => ({
    id: `ex-${i + 1}`,
    name,
    icon,
    category,
    equipment,
    primary,
    weighted: weighted ?? true,
    isDefault: true
  })
);
