import type { DietPlan, PlanItem } from '$lib/types';
import { persisted } from '$lib/utils/persist';
import { newId } from '$lib/utils/id';

export const plans = persisted<DietPlan[]>('luxifit.plans', []);

export function addPlan(name: string, items: PlanItem[]): DietPlan {
  const plan: DietPlan = { id: newId(), name, items };
  plans.update((list) => [plan, ...list]);
  return plan;
}

export function updatePlan(p: DietPlan): void {
  plans.update((list) => list.map((x) => (x.id === p.id ? p : x)));
}

export function deletePlan(id: string): void {
  plans.update((list) => list.filter((x) => x.id !== id));
}
