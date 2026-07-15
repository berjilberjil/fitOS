import { json, error } from '@sveltejs/kit';
import type { RequestHandler } from './$types';
import { env } from '$env/dynamic/private';
import { generateObject } from 'ai';
import { createGoogleGenerativeAI } from '@ai-sdk/google';
import { z } from 'zod';

const FoodLogSchema = z.object({
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

interface FoodLite { id: string; name: string; serving: string }

function buildPrompt(transcript: string, foods: FoodLite[], plannedFoodIds: string[]): string {
  const list = foods.map((f) => `${f.id} | ${f.name} | serving: ${f.serving}`).join('\n');
  const planned = plannedFoodIds.length ? plannedFoodIds.join(', ') : '(none)';
  return [
    `You convert a spoken meal note into structured food-log entries for a Tamil-Nadu fitness app.`,
    ``,
    `The user said: "${transcript}"`,
    ``,
    `Available foods (id | name | serving size):`,
    list,
    ``,
    `Today's planned food ids (prefer these when a spoken food is ambiguous): ${planned}`,
    ``,
    `Rules:`,
    `- Break the note into the individual foods the user said they ate, each with an amount.`,
    `- Match each spoken food to the BEST food id above by meaning (Tamil-Nadu foods: chapati, idli, dosa, milk, egg, rice, sambar, etc.). If nothing reasonably matches, set foodId to null but still fill foodName.`,
    `- quantity = number of SERVINGS of the matched food. Convert the spoken amount using that food's serving size. Examples: serving "1 chapati" + "3 chapati" -> 3; serving "1 cup" (~240 ml) + "100 ml milk" -> ~0.42; serving "1 egg" + "2 eggs" -> 2. Round to 2 decimals.`,
    `- meal: breakfast / lunch / dinner / snacks only if the user named it or clearly implied a time; otherwise null.`,
    `- Only include foods the user actually said they ate.`
  ].join('\n');
}

export const POST: RequestHandler = async ({ request, locals }) => {
  if (!locals.user) throw error(401, 'Not logged in');
  const apiKey = env.GEMINI_API_KEY;
  if (!apiKey) throw error(503, 'Voice logging is not configured on the server');

  const body = await request.json().catch(() => ({}));
  const transcript = String(body.transcript ?? '').trim();
  const foods: FoodLite[] = Array.isArray(body.foods) ? body.foods : [];
  const plannedFoodIds: string[] = Array.isArray(body.plannedFoodIds) ? body.plannedFoodIds : [];
  if (!transcript) throw error(400, 'Nothing to parse');

  try {
    const google = createGoogleGenerativeAI({ apiKey });
    const { object } = await generateObject({
      model: google(env.GEMINI_MODEL ?? 'gemini-2.5-flash'),
      schema: FoodLogSchema,
      prompt: buildPrompt(transcript, foods, plannedFoodIds)
    });
    return json(object);
  } catch (e) {
    throw error(502, `Could not understand that: ${(e as Error)?.message ?? 'try again'}`);
  }
};
