// Verified exercise demo media, keyed by seed exercise id (ex-1 .. ex-N).
//   gif   → animated demonstration (ExerciseDB open mirror) shown in the detail popup
//   still → public-domain photo (free-exercise-db) used as the grid thumbnail
// Custom user-added exercises have no entry → UI falls back to the emoji icon.
//
// Sources (all 92 URLs verified HTTP 200):
//   GIF:   https://static.exercisedb.dev/media/{id}.gif   (open mirror, stable, no key)
//   Still: https://raw.githubusercontent.com/yuhonas/free-exercise-db  (public domain)

export interface ExerciseMedia { gif?: string; still?: string; }

const GIF = 'https://static.exercisedb.dev/media/';
const STILL = 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/';

// [id, gifId, stillFolder]
const rows: [string, string, string][] = [
  ['ex-1', 'EIeI8Vf', 'Barbell_Bench_Press_-_Medium_Grip'],
  ['ex-2', 'PG1kcIb', 'Incline_Dumbbell_Press'],
  ['ex-3', 'WbNq5Xu', 'Leverage_Chest_Press'],
  ['ex-4', '0CXGHya', 'Cable_Crossover'],
  ['ex-5', 'tBWXbIT', 'Butterfly'],
  ['ex-6', '9WTm7dq', 'Dips_-_Chest_Version'],
  ['ex-7', '4Jt8QsQ', 'Pushups'],
  ['ex-8', 'ila4NZS', 'Barbell_Deadlift'],
  ['ex-9', '0V2YQjW', 'Pullups'],
  ['ex-10', '4IKbhHV', 'Wide-Grip_Lat_Pulldown'],
  ['ex-11', 'eZyBC3j', 'Bent_Over_Barbell_Row'],
  ['ex-12', 'fUBheHs', 'Seated_Cable_Rows'],
  ['ex-13', 'BJ0Hz5L', 'One-Arm_Dumbbell_Row'],
  ['ex-14', 'wqNPGCg', 'Face_Pull'],
  ['ex-15', 'kTbSH9h', 'Barbell_Shoulder_Press'],
  ['ex-16', 'znQUdHY', 'Dumbbell_Shoulder_Press'],
  ['ex-17', 'DsgkuIt', 'Side_Lateral_Raise'],
  ['ex-18', '3eGE2JC', 'Front_Dumbbell_Raise'],
  ['ex-19', 'aqvSOQE', 'Reverse_Machine_Flyes'],
  ['ex-20', 'dG7tG5y', 'Barbell_Shrug'],
  ['ex-21', '25GPyDY', 'Barbell_Curl'],
  ['ex-22', 'NbVPDMW', 'Dumbbell_Bicep_Curl'],
  ['ex-23', '2NpxjC1', 'Hammer_Curls'],
  ['ex-24', 'jivWf8n', 'Preacher_Curl'],
  ['ex-25', 'gAwDzB3', 'Triceps_Pushdown'],
  ['ex-26', '2IxROQ1', 'Cable_Rope_Overhead_Triceps_Extension'],
  ['ex-27', 'J6Dx1Mu', 'Close-Grip_Barbell_Bench_Press'],
  ['ex-28', 'h8LFzo9', 'EZ-Bar_Skullcrusher'],
  ['ex-29', 'qXTaZnJ', 'Barbell_Squat'],
  ['ex-30', '2Qh2J1e', 'Leg_Press'],
  ['ex-31', 'wQ2c4XD', 'Romanian_Deadlift'],
  ['ex-32', 'my33uHU', 'Leg_Extensions'],
  ['ex-33', '17lJ1kr', 'Lying_Leg_Curls'],
  ['ex-34', 'IZVHb27', 'Dumbbell_Lunges'],
  ['ex-35', 'qx4fgX7', 'Split_Squat_with_Dumbbells'],
  ['ex-36', 'Pjbc0Kt', 'Barbell_Hip_Thrust'],
  ['ex-37', 'ykUOVze', 'Standing_Calf_Raises'],
  ['ex-38', 'hCjGsRQ', 'Plank'],
  ['ex-39', 'I3tsCnC', 'Hanging_Leg_Raise'],
  ['ex-40', 'WW95auq', 'Cable_Crunch'],
  ['ex-41', 'XVDdcoj', 'Russian_Twist'],
  ['ex-42', 'KtRomty', 'Ab_Roller'],
  ['ex-43', 'CcWEoWV', 'Running_Treadmill'],
  ['ex-44', 'rjtuP6X', 'Walking_Treadmill'],
  ['ex-45', 'H1PESYI', 'Recumbent_Bike'],
  ['ex-46', 'IGjKj1v', 'Seated_Cable_Rows'],
  // ---- added exercises ----
  ['ex-49', '3TZduzM', 'Barbell_Incline_Bench_Press_-_Medium_Grip'],
  ['ex-50', 'GrO65fd', 'Decline_Barbell_Bench_Press'],
  ['ex-51', 'ESOd5Pl', 'Dumbbell_Flyes'],
  ['ex-52', 'aaXr7ld', 'T-Bar_Row_with_Handle'],
  ['ex-53', 'T2mxWqc', 'Chin-Up'],
  ['ex-54', 'rUXfn3R', 'Hyperextensions_Back_Extensions'],
  ['ex-55', 'x69MAlq', 'Straight-Arm_Pulldown'],
  ['ex-56', 'Xy4jlWA', 'Arnold_Dumbbell_Press'],
  ['ex-57', 'UDlhcO8', 'Upright_Barbell_Row'],
  ['ex-58', 'goJ6ezq', 'Cable_Seated_Lateral_Raise'],
  ['ex-59', 'gvsWLQw', 'Concentration_Curls'],
  ['ex-60', 'BCGQ6J5', 'Standing_Biceps_Cable_Curl'],
  ['ex-61', '6TG6x2w', 'EZ-Bar_Curl'],
  ['ex-62', '9RT8oQW', 'Bench_Dips'],
  ['ex-63', 'zG0zs85', 'Front_Barbell_Squat'],
  ['ex-64', 'Qa55kX1', 'Hack_Squat'],
  ['ex-65', 'yn8yg1r', 'Goblet_Squat'],
  ['ex-66', 'aXtJhlg', 'Dumbbell_Step_Ups'],
  ['ex-67', 'Zg3XY7P', 'Seated_Leg_Curl'],
  ['ex-68', 'bOOdeyc', 'Seated_Calf_Raise'],
  ['ex-69', 'kjJ3VoQ', 'Crunches'],
  ['ex-70', 'tZkGYZ9', 'Air_Bike'],
  ['ex-71', 'RJgzwny', 'Mountain_Climbers'],
  ['ex-72', 'WhuFnR7', 'Flat_Bench_Lying_Leg_Raise'],
  ['ex-73', 'VO2qeJg', 'Push_Up_to_Side_Plank'],
  ['ex-74', 'rjtuP6X', 'Elliptical_Trainer'],
  ['ex-75', 'RJa4tCo', 'Battling_Ropes'],
  ['ex-76', 'dK9394r', ''], // burpee: gif only, no free still
  // ---- boxing (mostly emoji fallback) ----
  ['ex-79', 'hoXt6wv', ''], // hook: gif only
  ['ex-82', '', 'Heavy_Bag_Thrust'] // heavy bag: still only
];

export const exerciseMedia: Record<string, ExerciseMedia> = Object.fromEntries(
  rows.map(([id, gif, still]) => [
    id,
    { gif: gif ? `${GIF}${gif}.gif` : undefined, still: still ? `${STILL}${still}/0.jpg` : undefined }
  ])
);

// Direct full-URL media (e.g. Wikimedia photos) for exercises the CDN sets miss.
const directMedia: Record<string, ExerciseMedia> = {
  'ex-77': { still: 'https://upload.wikimedia.org/wikipedia/commons/thumb/d/d0/Allongecolor.jpg/330px-Allongecolor.jpg' },
  'ex-78': { still: 'https://upload.wikimedia.org/wikipedia/commons/thumb/1/14/Retrait4color.jpg/330px-Retrait4color.jpg' },
  'ex-80': { still: 'https://upload.wikimedia.org/wikipedia/commons/thumb/4/4d/Uppercut4.jpg/330px-Uppercut4.jpg' },
  'ex-81': { still: 'https://upload.wikimedia.org/wikipedia/commons/thumb/2/2a/Boxing_Tournament_in_Aid_of_King_George%27s_Fund_For_Sailors_at_the_Royal_Naval_Air_Station%2C_Henstridge%2C_Somerset%2C_July_1945_A29806.jpg/330px-Boxing_Tournament_in_Aid_of_King_George%27s_Fund_For_Sailors_at_the_Royal_Naval_Air_Station%2C_Henstridge%2C_Somerset%2C_July_1945_A29806.jpg' },
  'ex-83': { still: 'https://upload.wikimedia.org/wikipedia/commons/thumb/a/ab/Chalky_Wright_speed_bag_1942.jpg/500px-Chalky_Wright_speed_bag_1942.jpg' }
};
for (const [id, m] of Object.entries(directMedia)) {
  exerciseMedia[id] = { ...exerciseMedia[id], ...m };
}

export const exGif = (id: string): string | undefined => exerciseMedia[id]?.gif;
export const exStill = (id: string): string | undefined => exerciseMedia[id]?.still;
/** Best thumbnail for lists/grids: the animated GIF (crisp when shown small), else the still. */
export const exThumb = (id: string): string | undefined => exerciseMedia[id]?.gif ?? exerciseMedia[id]?.still;
export const hasDemo = (id: string): boolean => !!(exerciseMedia[id]?.gif || exerciseMedia[id]?.still);
