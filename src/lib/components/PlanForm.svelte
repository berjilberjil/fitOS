<script lang="ts">
  import type { DietPlan, PlanItem, Macros } from '$lib/types';
  import { foods, findFood } from '$lib/stores/foods';
  import { scaleMacros, sumMacros } from '$lib/utils/nutrition';
  import Modal from './Modal.svelte';
  import FoodPicker from './FoodPicker.svelte';

  let { initial = null, onsave, ondelete }: {
    initial?: DietPlan | null;
    onsave: (name: string, items: PlanItem[]) => void;
    ondelete?: () => void;
  } = $props();

  let name = $state(initial?.name ?? '');
  let items = $state<PlanItem[]>(initial ? [...initial.items] : []);
  let picking = $state(false);

  const rows = $derived(
    items.map((it) => {
      const food = findFood($foods, it.foodId);
      return { it, food, macros: food ? scaleMacros(food.perServing, it.quantity) : null };
    })
  );
  const total = $derived(
    sumMacros(rows.map((r) => r.macros).filter((m): m is Macros => m !== null))
  );

  function addItem(foodId: string, quantity: number) {
    items = [...items, { foodId, quantity }];
    picking = false;
  }
  function removeItem(i: number) {
    items = items.filter((_, idx) => idx !== i);
  }
  function save() {
    if (name.trim() && items.length) onsave(name.trim(), items);
  }
</script>

<div class="form">
  <label>Plan name<input bind:value={name} placeholder="e.g. Cut Day" /></label>

  <div class="rows">
    {#each rows as r, i (i)}
      <div class="prow card">
        <div>
          <div class="pn">{r.food?.name ?? 'Deleted food'} <span class="muted">×{r.it.quantity}</span></div>
          {#if r.macros}<div class="muted pm">{r.macros.calories} kcal · P {r.macros.protein}</div>{/if}
        </div>
        <button class="rm" onclick={() => removeItem(i)} aria-label="Remove">✕</button>
      </div>
    {/each}
    {#if items.length === 0}<p class="muted">No foods yet.</p>{/if}
  </div>

  <div class="total muted">Total: {total.calories} kcal · P {total.protein} · C {total.carbs} · F {total.fats}</div>

  <button class="btn-ghost" onclick={() => (picking = true)}>+ Add food to plan</button>
  <div class="actions">
    <button class="btn-primary" onclick={save}>Save plan</button>
    {#if ondelete}<button class="btn-ghost" onclick={ondelete}>Delete</button>{/if}
  </div>
</div>

<Modal open={picking} title="Add to plan" onclose={() => (picking = false)}>
  <FoodPicker onadd={addItem} />
</Modal>

<style>
  .form { display: flex; flex-direction: column; gap: 12px; }
  label { display: flex; flex-direction: column; gap: 6px; font-size: 13px; font-weight: 600; color: var(--muted); }
  input { background: var(--surface-2); color: var(--text); border: 1px solid #2a2a2e; border-radius: 10px; padding: 11px; font-size: 16px; }
  .rows { display: flex; flex-direction: column; gap: 8px; }
  .prow { padding: 10px 12px; display: flex; align-items: center; justify-content: space-between; }
  .pn { font-weight: 700; font-size: 14px; }
  .pm { font-size: 12px; }
  .rm { background: var(--surface-2); border: 1px solid #2a2a2e; color: var(--muted); border-radius: 8px; width: 30px; height: 30px; }
  .total { font-size: 13px; font-weight: 600; }
  .actions { display: flex; gap: 10px; }
  .actions .btn-primary { flex: 1; }
</style>
