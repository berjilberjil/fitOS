import type { WorkoutDayLog, WorkoutWeekPlan, LoggedExercise } from '$lib/types';
import { persisted } from '$lib/stores/sync';
import { weekdayOf } from './log';
import { DEFAULT_SETS, DEFAULT_REPS } from '$lib/data/workouts';

export const workoutLog = persisted<Record<string, WorkoutDayLog>>('luxifit.workoutlog', {});

/**
 * Most recent working weight logged for an exercise on any date strictly before
 * `beforeDate`. Powers progressive overload — this session starts at last time's
 * weight so you know exactly what to beat.
 */
export function lastWeightFor(
  map: Record<string, WorkoutDayLog>,
  exerciseId: string,
  beforeDate: string
): number | undefined {
  const dates = Object.keys(map)
    .filter((d) => d < beforeDate)
    .sort()
    .reverse();
  for (const d of dates) {
    const hit = map[d]?.items?.find((it) => it.exerciseId === exerciseId && it.weightKg > 0);
    if (hit) return hit.weightKg;
  }
  return undefined;
}

/**
 * The day's session, seeded from the weekday routine the first time a date is
 * opened. Working weight starts from the last time you trained that exercise.
 */
export function getOrSeedWorkoutDay(
  map: Record<string, WorkoutDayLog>,
  date: string,
  plan: WorkoutWeekPlan
): WorkoutDayLog {
  const existing = map[date];
  if (existing) return { date, rest: !!existing.rest, items: existing.items ?? [] };

  const routine = plan[weekdayOf(date)];
  if (!routine) return { date, rest: false, items: [] };
  if (routine.rest) return { date, rest: true, items: [] };

  const items: LoggedExercise[] = routine.items.map((it) => ({
    exerciseId: it.exerciseId,
    sets: it.sets,
    reps: it.reps,
    weightKg: lastWeightFor(map, it.exerciseId, date) ?? 0,
    done: false
  }));
  return { date, rest: false, items };
}

function edit(
  date: string,
  plan: WorkoutWeekPlan,
  fn: (day: WorkoutDayLog) => WorkoutDayLog
): void {
  workoutLog.update((map) => {
    const day = getOrSeedWorkoutDay(map, date, plan);
    return { ...map, [date]: fn(day) };
  });
}

const round = (n: number) => Math.max(Math.round(n * 100) / 100, 0);

export function bumpWeight(date: string, index: number, delta: number, plan: WorkoutWeekPlan): void {
  edit(date, plan, (day) => ({
    ...day,
    items: day.items.map((it, i) => (i === index ? { ...it, weightKg: round(it.weightKg + delta) } : it))
  }));
}

export function setWeight(date: string, index: number, weightKg: number, plan: WorkoutWeekPlan): void {
  edit(date, plan, (day) => ({
    ...day,
    items: day.items.map((it, i) => (i === index ? { ...it, weightKg: round(weightKg) } : it))
  }));
}

export function setLogSets(date: string, index: number, sets: number, plan: WorkoutWeekPlan): void {
  edit(date, plan, (day) => ({
    ...day,
    items: day.items.map((it, i) => (i === index ? { ...it, sets: Math.max(Math.round(sets), 1) } : it))
  }));
}

export function setLogReps(date: string, index: number, reps: number, plan: WorkoutWeekPlan): void {
  edit(date, plan, (day) => ({
    ...day,
    items: day.items.map((it, i) => (i === index ? { ...it, reps: Math.max(Math.round(reps), 1) } : it))
  }));
}

export function toggleDone(date: string, index: number, plan: WorkoutWeekPlan): void {
  edit(date, plan, (day) => ({
    ...day,
    items: day.items.map((it, i) => (i === index ? { ...it, done: !it.done } : it))
  }));
}

export function swapLogExercise(date: string, index: number, exerciseId: string, plan: WorkoutWeekPlan): void {
  workoutLog.update((map) => {
    const day = getOrSeedWorkoutDay(map, date, plan);
    const items = day.items.map((it, i) =>
      i === index
        ? { ...it, exerciseId, weightKg: lastWeightFor(map, exerciseId, date) ?? 0, done: false }
        : it
    );
    return { ...map, [date]: { ...day, items } };
  });
}

export function addExerciseToDay(date: string, exerciseId: string, plan: WorkoutWeekPlan): void {
  workoutLog.update((map) => {
    const day = getOrSeedWorkoutDay(map, date, plan);
    const item: LoggedExercise = {
      exerciseId,
      sets: DEFAULT_SETS,
      reps: DEFAULT_REPS,
      weightKg: lastWeightFor(map, exerciseId, date) ?? 0,
      done: false
    };
    return { ...map, [date]: { ...day, rest: false, items: [...day.items, item] } };
  });
}

export function removeFromDay(date: string, index: number, plan: WorkoutWeekPlan): void {
  edit(date, plan, (day) => ({ ...day, items: day.items.filter((_, i) => i !== index) }));
}

export function setDayRest(date: string, rest: boolean, plan: WorkoutWeekPlan): void {
  workoutLog.update((map) => {
    const day = getOrSeedWorkoutDay(map, date, plan);
    return { ...map, [date]: { ...day, rest, items: rest ? [] : day.items } };
  });
}
