import { json, error } from '@sveltejs/kit';
import type { RequestHandler } from './$types';
import { env } from '$env/dynamic/private';
import { generateObject } from 'ai';
import { createGoogleGenerativeAI } from '@ai-sdk/google';
import { z } from 'zod';

/**
 * Unified voice log — food, workout, or both in one utterance.
 * Client still does STT; this only structures meaning.
 */
const UnifiedSchema = z.object({
  kind: z.enum(['food', 'workout', 'mixed', 'unknown']),
  meal: z.enum(['breakfast', 'lunch', 'dinner', 'snacks']).nullable(),
  foodItems: z.array(
    z.object({
      spoken: z.string(),
      foodId: z.string().nullable(),
      foodName: z.string(),
      quantity: z.number()
    })
  ),
  workoutItems: z.array(
    z.object({
      spoken: z.string(),
      exerciseId: z.string().nullable(),
      exerciseName: z.string(),
      sets: z.number().nullable(),
      reps: z.number().nullable(),
      weightKg: z.number().nullable()
    })
  )
});

// Back-compat shape some older clients still expect
const FoodOnlySchema = z.object({
  meal: z.enum(['breakfast', 'lunch', 'dinner', 'snacks']).nullable(),
  items: z.array(
    z.object({
      spoken: z.string(),
      foodId: z.string().nullable(),
      foodName: z.string(),
      quantity: z.number()
    })
  )
});

interface FoodLite {
  id: string;
  name: string;
  serving: string;
}
interface ExerciseLite {
  id: string;
  name: string;
  primary: string;
}

function buildPrompt(
  transcript: string,
  foods: FoodLite[],
  exercises: ExerciseLite[],
  plannedFoodIds: string[],
  plannedExerciseIds: string[]
): string {
  const foodList = foods.map((f) => `${f.id} | ${f.name} | serving: ${f.serving}`).join('\n');
  const exList = exercises.map((e) => `${e.id} | ${e.name} | targets: ${e.primary}`).join('\n');
  const plannedF = plannedFoodIds.length ? plannedFoodIds.join(', ') : '(none)';
  const plannedE = plannedExerciseIds.length ? plannedExerciseIds.join(', ') : '(none)';
  return [
    `You convert a spoken fitness note into structured food and/or workout log entries for a Tamil-Nadu fitness app (fitOS).`,
    ``,
    `The user said: "${transcript}"`,
    ``,
    `Available foods (id | name | serving):`,
    foodList || '(none)',
    ``,
    `Available exercises (id | name | targets):`,
    exList || '(none)',
    ``,
    `Today's planned food ids (prefer when ambiguous): ${plannedF}`,
    `Today's planned exercise ids (prefer when ambiguous): ${plannedE}`,
    ``,
    `Rules:`,
    `- Detect intent: food (meals/drinks), workout (sets/reps/exercises/weights), mixed, or unknown.`,
    `- Food: break into foods eaten with quantity in SERVINGS of the matched food. Match Tamil-Nadu foods (chapati, idli, dosa, milk, egg, rice…). If no match, foodId=null but keep foodName.`,
    `- Workout: each exercise the user trained. Match exercise id by name meaning. sets/reps/weightKg null if not said. weightKg in kilograms if spoken (e.g. "60 kilos" → 60).`,
    `- meal: only if named or clearly implied; else null.`,
    `- Only include what the user actually said they ate or trained.`,
    `- kind must reflect what you filled: foodItems only → food; workoutItems only → workout; both → mixed; neither → unknown.`
  ].join('\n');
}

export const POST: RequestHandler = async ({ request, locals }) => {
  if (!locals.user) throw error(401, 'Not logged in');
  const apiKey = env.GEMINI_API_KEY;
  if (!apiKey) throw error(503, 'Voice logging is not configured on the server');

  const body = await request.json().catch(() => ({}));
  const transcript = String(body.transcript ?? '').trim();
  const foods: FoodLite[] = Array.isArray(body.foods) ? body.foods : [];
  const exercises: ExerciseLite[] = Array.isArray(body.exercises) ? body.exercises : [];
  const plannedFoodIds: string[] = Array.isArray(body.plannedFoodIds) ? body.plannedFoodIds : [];
  const plannedExerciseIds: string[] = Array.isArray(body.plannedExerciseIds)
    ? body.plannedExerciseIds
    : [];
  // legacy: mode food-only still works
  const foodOnly = body.mode === 'food' || (exercises.length === 0 && !body.unified);
  if (!transcript) throw error(400, 'Nothing to parse');

  try {
    const google = createGoogleGenerativeAI({ apiKey });
    if (foodOnly && exercises.length === 0) {
      // Keep old schema path for simple food-only clients
      const { object } = await generateObject({
        model: google(env.GEMINI_MODEL ?? 'gemini-2.5-flash'),
        schema: FoodOnlySchema,
        prompt: [
          `You convert a spoken meal note into structured food-log entries.`,
          `User said: "${transcript}"`,
          `Foods:\n${foods.map((f) => `${f.id} | ${f.name} | ${f.serving}`).join('\n')}`,
          `Planned: ${plannedFoodIds.join(', ') || '(none)'}`,
          `quantity = servings. meal nullable.`
        ].join('\n')
      });
      return json({
        kind: object.items.length ? 'food' : 'unknown',
        meal: object.meal,
        foodItems: object.items,
        workoutItems: [],
        // back-compat
        items: object.items
      });
    }

    const { object } = await generateObject({
      model: google(env.GEMINI_MODEL ?? 'gemini-2.5-flash'),
      schema: UnifiedSchema,
      prompt: buildPrompt(transcript, foods, exercises, plannedFoodIds, plannedExerciseIds)
    });

    // back-compat field
    return json({
      ...object,
      items: object.foodItems
    });
  } catch (e) {
    throw error(502, `Could not understand that: ${(e as Error)?.message ?? 'try again'}`);
  }
};
