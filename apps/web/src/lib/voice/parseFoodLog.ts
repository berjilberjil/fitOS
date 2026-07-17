import type { Food } from '$lib/types';

// The transcript is parsed on the SERVER (/api/voice/parse) so the Gemini key
// never ships to the browser. This is just the client caller + result type.

export interface ParsedFoodLog {
  meal: 'breakfast' | 'lunch' | 'dinner' | 'snacks' | null;
  items: { spoken: string; foodId: string | null; foodName: string; quantity: number }[];
}

export async function parseFoodLog(params: {
  transcript: string;
  foods: Food[];
  plannedFoodIds?: string[];
}): Promise<ParsedFoodLog> {
  const res = await fetch('/api/voice/parse', {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify({
      transcript: params.transcript,
      foods: params.foods.map((f) => ({ id: f.id, name: f.name, serving: f.servingLabel })),
      plannedFoodIds: params.plannedFoodIds ?? [],
      // Explicit food-only mode so the unified API always returns `items`.
      mode: 'food'
    })
  });
  if (!res.ok) {
    const msg = (await res.json().catch(() => ({}))).message ?? 'Voice parse failed';
    throw new Error(msg);
  }
  const data = (await res.json()) as {
    meal?: ParsedFoodLog['meal'];
    items?: ParsedFoodLog['items'];
    foodItems?: ParsedFoodLog['items'];
  };
  return {
    meal: data.meal ?? null,
    items: data.items ?? data.foodItems ?? []
  };
}
