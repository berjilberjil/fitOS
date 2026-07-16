import { json } from '@sveltejs/kit';
import type { RequestHandler } from './$types';
import { seedFoods } from '$lib/data/seed-foods';
import { seedExercises } from '$lib/data/seed-exercises';

// Public, read-only catalog for native clients (apps/ios). Re-serves the exact
// same seed data the web bundle uses, so there is ONE source of truth. Cached
// hard at the edge — this payload only changes on deploy.
export const GET: RequestHandler = () => {
  return json(
    { foods: seedFoods, exercises: seedExercises },
    { headers: { 'cache-control': 'public, max-age=3600' } }
  );
};
