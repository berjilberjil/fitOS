import type { WorkoutWeekPlan } from '$lib/types';
import { persisted } from '$lib/stores/sync';
import { emptyWorkoutWeek, emptyWorkoutDay, DEFAULT_SETS, DEFAULT_REPS } from '$lib/data/workouts';

export const workoutPlan = persisted<WorkoutWeekPlan>('luxifit.workoutplan', emptyWorkoutWeek());

/** Guard against older/partial persisted shapes. */
function ensureDay(w: WorkoutWeekPlan, weekday: number): WorkoutWeekPlan {
  if (!w[weekday]) w[weekday] = emptyWorkoutDay();
  if (!Array.isArray(w[weekday].items)) w[weekday] = { rest: !!w[weekday].rest, items: [] };
  return w;
}

export function addPlanExercise(weekday: number, exerciseId: string, sets = DEFAULT_SETS, reps = DEFAULT_REPS): void {
  workoutPlan.update((w) => {
    const next = ensureDay({ ...w }, weekday);
    const day = { rest: false, items: [...next[weekday].items, { exerciseId, sets, reps }] };
    return { ...next, [weekday]: day };
  });
}

export function setPlanSets(weekday: number, index: number, sets: number): void {
  workoutPlan.update((w) => {
    const next = ensureDay({ ...w }, weekday);
    const items = next[weekday].items.map((it, i) =>
      i === index ? { ...it, sets: Math.max(Math.round(sets), 1) } : it
    );
    return { ...next, [weekday]: { ...next[weekday], items } };
  });
}

export function setPlanReps(weekday: number, index: number, reps: number): void {
  workoutPlan.update((w) => {
    const next = ensureDay({ ...w }, weekday);
    const items = next[weekday].items.map((it, i) =>
      i === index ? { ...it, reps: Math.max(Math.round(reps), 1) } : it
    );
    return { ...next, [weekday]: { ...next[weekday], items } };
  });
}

export function swapPlanExercise(weekday: number, index: number, exerciseId: string): void {
  workoutPlan.update((w) => {
    const next = ensureDay({ ...w }, weekday);
    const items = next[weekday].items.map((it, i) => (i === index ? { ...it, exerciseId } : it));
    return { ...next, [weekday]: { ...next[weekday], items } };
  });
}

export function removePlanExercise(weekday: number, index: number): void {
  workoutPlan.update((w) => {
    const next = ensureDay({ ...w }, weekday);
    const items = next[weekday].items.filter((_, i) => i !== index);
    return { ...next, [weekday]: { ...next[weekday], items } };
  });
}

export function setRestDay(weekday: number, rest: boolean): void {
  workoutPlan.update((w) => {
    const next = ensureDay({ ...w }, weekday);
    return { ...next, [weekday]: { ...next[weekday], rest } };
  });
}

/** Copy one weekday's whole routine (rest flag + exercises) onto given weekdays. */
export function copyWorkoutDay(from: number, targets: number[]): void {
  workoutPlan.update((w) => {
    let next = ensureDay({ ...w }, from);
    for (const to of targets) {
      if (to === from) continue;
      next = ensureDay(next, to);
      next = {
        ...next,
        [to]: { rest: next[from].rest, items: next[from].items.map((it) => ({ ...it })) }
      };
    }
    return next;
  });
}
