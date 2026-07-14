<script lang="ts">
  import type { MealKey, Food } from '$lib/types';
  import { profile } from '$lib/stores/profile';
  import { foods, findFood } from '$lib/stores/foods';
  import { weekPlan } from '$lib/stores/plan';
  import {
    logMap, dateKey, weekdayOf, getOrSeedDay, setQty, swapFood, addFoodToMeal, removeFromMeal
  } from '$lib/stores/log';
  import { scaleMacros, sumMacros, bmr, tdee, proteinGoal } from '$lib/utils/nutrition';
  import { MEALS, MEAL_KEYS, WEEKDAYS_LONG } from '$lib/data/meals';
  import MacroRing from './MacroRing.svelte';
  import MacroBar from './MacroBar.svelte';
  import MealSection from './MealSection.svelte';
  import Modal from './Modal.svelte';
  import FoodPicker from './FoodPicker.svelte';

  interface Row { food: Food; quantity: number; index: number; plannedHint?: number; }

  let offset = $state(0);
  function dateForOffset(o: number): string {
    const d = new Date();
    d.setDate(d.getDate() + o);
    return dateKey(d);
  }
  const date = $derived(dateForOffset(offset));
  const day = $derived(getOrSeedDay($logMap, date, $weekPlan));

  function rowsFor(meal: MealKey): Row[] {
    const planned = $weekPlan[weekdayOf(date)]?.[meal] ?? [];
    const out: Row[] = [];
    day.meals[meal].forEach((it, index) => {
      const food = findFood($foods, it.foodId);
      if (food) out.push({ food, quantity: it.quantity, index, plannedHint: planned[index]?.quantity });
    });
    return out;
  }
  const mealKcal = (meal: MealKey) =>
    rowsFor(meal).reduce((s, r) => s + scaleMacros(r.food.perServing, r.quantity).calories, 0);

  const allRows = $derived(MEAL_KEYS.flatMap(rowsFor));
  const totals = $derived(sumMacros(allRows.map((r) => scaleMacros(r.food.perServing, r.quantity))));
  const calGoal = $derived(
    tdee(bmr($profile.sex, $profile.currentWeightKg, $profile.heightCm, $profile.age), $profile.activity)
  );
  const protGoal = $derived(proteinGoal($profile.currentWeightKg));

  const relLabel = $derived(offset === 0 ? 'Today' : offset === -1 ? 'Yesterday' : offset === 1 ? 'Tomorrow' : date);

  // add/swap picker
  let picker = $state<{ meal: MealKey; index: number | null } | null>(null);
  function handlePick(foodId: string, qty: number) {
    if (!picker) return;
    if (picker.index === null) addFoodToMeal(date, picker.meal, foodId, qty, $weekPlan);
    else swapFood(date, picker.meal, picker.index, foodId, $weekPlan);
    picker = null;
  }
</script>

<div class="hero card">
  <div class="datebar">
    <button class="icon-btn" onclick={() => (offset -= 1)} aria-label="Previous day">‹</button>
    <div class="dlabel">
      <span class="rel">{relLabel}</span>
      <span class="wd muted">{WEEKDAYS_LONG[weekdayOf(date)]}</span>
    </div>
    <button class="icon-btn" onclick={() => (offset += 1)} aria-label="Next day">›</button>
  </div>

  <div class="rings">
    <MacroRing value={totals.calories} goal={calGoal} label="Calories" unit="kcal" />
    <MacroRing value={totals.protein} goal={protGoal} label="Protein" unit="g" color="var(--info)" />
  </div>

  <div class="bars">
    <MacroBar label="Carbs" value={totals.carbs} unit="g" color="var(--warn)" />
    <MacroBar label="Fiber" value={totals.fiber} unit="g" color="var(--ok)" />
    <MacroBar label="Fats" value={totals.fats} unit="g" color="var(--red)" />
  </div>
</div>

<div class="meals stagger">
  {#each MEALS as meal}
    <MealSection
      {meal}
      rows={rowsFor(meal.key)}
      kcal={mealKcal(meal.key)}
      onqty={(index, v) => setQty(date, meal.key, index, v, $weekPlan)}
      onswap={(index) => (picker = { meal: meal.key, index })}
      onremove={(index) => removeFromMeal(date, meal.key, index, $weekPlan)}
      onadd={() => (picker = { meal: meal.key, index: null })}
    />
  {/each}
</div>

<Modal
  open={!!picker}
  title={picker?.index === null ? 'Add food' : 'Swap food'}
  onclose={() => (picker = null)}
>
  <FoodPicker onpick={handlePick} askQuantity={picker?.index === null} />
</Modal>

<style>
  .hero { padding: 16px; margin-bottom: 14px; }
  .datebar { display: flex; align-items: center; justify-content: space-between; margin-bottom: 8px; }
  .dlabel { text-align: center; display: flex; flex-direction: column; gap: 1px; }
  .rel { font-weight: 750; font-size: 17px; letter-spacing: -0.02em; }
  .wd { font-size: 12px; }
  .rings { display: flex; justify-content: space-around; padding: 6px 0 14px; }
  .bars { display: flex; flex-direction: column; gap: 13px; border-top: 1px solid var(--border); padding-top: 15px; }
  .meals { display: flex; flex-direction: column; gap: 12px; }
</style>
