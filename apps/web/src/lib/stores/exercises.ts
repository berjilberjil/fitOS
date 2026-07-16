import type { Exercise } from '$lib/types';
import { persisted } from '$lib/stores/sync';
import { newId } from '$lib/utils/id';
import { seedExercises } from '$lib/data/seed-exercises';

export const exercises = persisted<Exercise[]>('luxifit.exercises', seedExercises);

// Merge in default exercises shipped in later versions that aren't stored yet —
// preserves the user's own edits and custom additions (only appends missing ids).
exercises.update((list) => {
  const have = new Set(list.map((e) => e.id));
  const missing = seedExercises.filter((e) => !have.has(e.id));
  return missing.length ? [...list, ...missing] : list;
});

export function addExercise(input: Omit<Exercise, 'id' | 'isDefault'>): Exercise {
  const ex: Exercise = { ...input, id: newId(), isDefault: false };
  exercises.update((list) => [ex, ...list]);
  return ex;
}

export function updateExercise(ex: Exercise): void {
  exercises.update((list) => list.map((x) => (x.id === ex.id ? ex : x)));
}

export function deleteExercise(id: string): void {
  exercises.update((list) => list.filter((x) => x.id !== id));
}

export function findExercise(list: Exercise[], id: string): Exercise | undefined {
  return list.find((x) => x.id === id);
}
