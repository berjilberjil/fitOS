<script lang="ts">
  import { profile } from '$lib/stores/profile';
  import { foods, findFood } from '$lib/stores/foods';
  import { logMap, todayKey, getDay, addLogItem, removeLogItem, logItemFromFood } from '$lib/stores/log';
  import { sumMacros, bmr, tdee, proteinGoal } from '$lib/utils/nutrition';
  import MacroRing from './MacroRing.svelte';
  import MacroBar from './MacroBar.svelte';
  import Modal from './Modal.svelte';
  import Fab from './Fab.svelte';
  import FoodPicker from './FoodPicker.svelte';

  const date = todayKey();
  let picking = $state(false);

  const day = $derived(getDay($logMap, date));
  const totals = $derived(sumMacros(day.items.map((i) => i.macros)));
  const calGoal = $derived(
    tdee(bmr($profile.sex, $profile.currentWeightKg, $profile.heightCm, $profile.age), $profile.activity)
  );
  const protGoal = $derived(proteinGoal($profile.currentWeightKg));

  function add(foodId: string, quantity: number) {
    const food = findFood($foods, foodId);
    if (food) addLogItem(date, logItemFromFood(food, quantity));
    picking = false;
  }
</script>

<div class="rings card">
  <MacroRing value={totals.calories} goal={calGoal} label="Calories" unit="kcal" />
  <MacroRing value={totals.protein} goal={protGoal} label="Protein" unit="g" />
</div>

<div class="card bars">
  <MacroBar label="Carbs" value={totals.carbs} unit="g" />
  <MacroBar label="Fiber" value={totals.fiber} unit="g" />
  <MacroBar label="Fats" value={totals.fats} unit="g" />
</div>

<h2 class="h2" style="margin-top:8px">Today's food</h2>
<div class="items">
  {#each day.items as item, i (i)}
    <div class="item card">
      <div>
        <div class="iname">{item.name} <span class="muted">×{item.quantity}</span></div>
        <div class="muted im">{item.macros.calories} kcal · P {item.macros.protein} · C {item.macros.carbs} · F {item.macros.fats}</div>
      </div>
      <button class="rm" onclick={() => removeLogItem(date, i)} aria-label="Remove">✕</button>
    </div>
  {/each}
  {#if day.items.length === 0}<p class="muted">Nothing logged yet. Tap + to add food.</p>{/if}
</div>

<Fab onclick={() => (picking = true)} />

<Modal open={picking} title="Add food" onclose={() => (picking = false)}>
  <FoodPicker onadd={add} />
</Modal>

<style>
  .rings { display: flex; justify-content: space-around; padding: 16px; margin-bottom: 12px; }
  .bars { padding: 16px; display: flex; flex-direction: column; gap: 12px; }
  .items { display: flex; flex-direction: column; gap: 8px; margin-top: 8px; padding-bottom: 90px; }
  .item { padding: 12px; display: flex; align-items: center; justify-content: space-between; }
  .iname { font-weight: 700; font-size: 14px; }
  .im { font-size: 12px; }
  .rm { background: var(--surface-2); border: 1px solid #2a2a2e; color: var(--muted); border-radius: 8px; width: 32px; height: 32px; }
</style>
