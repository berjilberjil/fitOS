<script lang="ts">
  import type { MealKey, Food } from '$lib/types';
  import { foods, findFood } from '$lib/stores/foods';
  import { weekPlan, addPlanFood, setPlanQty, swapPlanFood, removePlanFood, copyDayPlan } from '$lib/stores/plan';
  import { scaleMacros } from '$lib/utils/nutrition';
  import { MEALS, MEAL_KEYS, WEEKDAYS, WEEKDAYS_LONG } from '$lib/data/meals';
  import MealSection from './MealSection.svelte';
  import Modal from './Modal.svelte';
  import FoodPicker from './FoodPicker.svelte';

  interface Row { food: Food; quantity: number; index: number; }

  let weekday = $state(new Date().getDay());

  function rowsFor(meal: MealKey): Row[] {
    const items = $weekPlan[weekday]?.[meal] ?? [];
    const out: Row[] = [];
    items.forEach((it, index) => {
      const food = findFood($foods, it.foodId);
      if (food) out.push({ food, quantity: it.quantity, index });
    });
    return out;
  }
  const mealKcal = (meal: MealKey) =>
    rowsFor(meal).reduce((s, r) => s + scaleMacros(r.food.perServing, r.quantity).calories, 0);
  const dayKcal = $derived(MEAL_KEYS.reduce((s, k) => s + mealKcal(k), 0));

  let picker = $state<{ meal: MealKey; index: number | null } | null>(null);
  function handlePick(foodId: string, qty: number) {
    if (!picker) return;
    if (picker.index === null) addPlanFood(weekday, picker.meal, foodId, qty);
    else swapPlanFood(weekday, picker.meal, picker.index, foodId);
    picker = null;
  }

  let copied = $state(false);
  function copyToAll() {
    for (let d = 0; d < 7; d++) if (d !== weekday) copyDayPlan(weekday, d);
    copied = true;
    setTimeout(() => (copied = false), 1600);
  }
</script>

<div class="intro">
  <p class="muted note">Set your routine once. Each day opens pre-filled from its weekday — you just adjust with ＋ / −.</p>
</div>

<div class="wdbar">
  {#each WEEKDAYS as w, i}
    <button class="wd" class:on={i === weekday} onclick={() => (weekday = i)}>{w}</button>
  {/each}
</div>

<div class="dayhead">
  <span class="dname">{WEEKDAYS_LONG[weekday]}</span>
  <span class="dk num muted">{dayKcal} kcal planned</span>
</div>

<div class="meals stagger">
  {#each MEALS as meal}
    <MealSection
      {meal}
      rows={rowsFor(meal.key)}
      kcal={mealKcal(meal.key)}
      onqty={(index, v) => setPlanQty(weekday, meal.key, index, v)}
      onswap={(index) => (picker = { meal: meal.key, index })}
      onremove={(index) => removePlanFood(weekday, meal.key, index)}
      onadd={() => (picker = { meal: meal.key, index: null })}
    />
  {/each}
</div>

<button class="btn btn-outline copy" onclick={copyToAll}>
  {copied ? 'Copied to every day ✓' : `Copy ${WEEKDAYS_LONG[weekday]} to every day`}
</button>

<Modal
  open={!!picker}
  title={picker?.index === null ? 'Add to plan' : 'Swap food'}
  onclose={() => (picker = null)}
>
  <FoodPicker onpick={handlePick} askQuantity={picker?.index === null} />
</Modal>

<style>
  .intro { margin-bottom: 12px; }
  .note { font-size: 13px; }
  .wdbar { display: flex; gap: 5px; overflow-x: auto; padding-bottom: 12px; }
  .wd {
    flex: 1; min-width: 44px; padding: 9px 0; border-radius: var(--radius-sm);
    background: var(--surface-2); border: 1px solid var(--border); color: var(--muted);
    font-weight: 700; font-size: 12px; transition: all var(--dur-fast) var(--ease);
  }
  .wd:hover { color: var(--text); }
  .wd.on { background: var(--red); color: #fff; border-color: var(--red); }
  .dayhead { display: flex; align-items: baseline; justify-content: space-between; margin-bottom: 12px; }
  .dname { font-weight: 750; font-size: 17px; letter-spacing: -0.02em; }
  .dk { font-size: 12px; }
  .meals { display: flex; flex-direction: column; gap: 12px; }
  .copy { width: 100%; margin-top: 16px; }
</style>
