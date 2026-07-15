<script lang="ts">
  import type { Food, Category, Macros } from '$lib/types';
  import { caloriesFromMacros } from '$lib/utils/nutrition';
  import Icon from './Icon.svelte';

  type FoodDraft = Omit<Food, 'id' | 'isDefault'>;

  let { initial = null, onsave, ondelete }: {
    initial?: Food | null;
    onsave: (f: FoodDraft) => void;
    ondelete?: () => void;
  } = $props();

  const categories: Category[] = ['protein', 'carb', 'veg', 'dairy', 'fruit', 'drink', 'junk', 'other'];

  let name = $state(initial?.name ?? '');
  const icon = initial?.icon ?? '';
  let category = $state<Category>(initial?.category ?? 'other');
  let servingLabel = $state(initial?.servingLabel ?? '1 serving');
  let protein = $state(initial?.perServing.protein ?? 0);
  let carbs = $state(initial?.perServing.carbs ?? 0);
  let fiber = $state(initial?.perServing.fiber ?? 0);
  let fats = $state(initial?.perServing.fats ?? 0);
  let vitamins = $state(initial?.vitamins ?? '');
  let isJunk = $state(initial?.isJunk ?? false);
  let calOverride = $state<number | null>(initial ? initial.perServing.calories : null);

  const autoCal = $derived(caloriesFromMacros({ protein, carbs, fiber, fats }));
  const calories = $derived(calOverride == null ? autoCal : calOverride);

  function save() {
    if (!name.trim()) return;
    const perServing: Macros = { calories, protein, carbs, fiber, fats };
    onsave({
      name: name.trim(), icon, category, servingLabel, perServing,
      vitamins: vitamins || undefined, isJunk
    });
  }
</script>

<div class="form">
  <div class="namerow">
    <div class="iconwrap">
      <span class="preview"><Icon icon="lucide:utensils" size={24} /></span>
    </div>
    <label class="grow">Name<input class="input" bind:value={name} placeholder="e.g. Chapati" /></label>
  </div>

  <div class="two">
    <label>Serving<input class="input" bind:value={servingLabel} placeholder="1 chapati" /></label>
    <label>Category
      <select class="select" bind:value={category}>{#each categories as c}<option value={c}>{c}</option>{/each}</select>
    </label>
  </div>

  <div class="grid">
    <label>Protein (g)<input class="input" type="number" step="0.1" bind:value={protein} /></label>
    <label>Carbs (g)<input class="input" type="number" step="0.1" bind:value={carbs} /></label>
    <label>Fiber (g)<input class="input" type="number" step="0.1" bind:value={fiber} /></label>
    <label>Fats (g)<input class="input" type="number" step="0.1" bind:value={fats} /></label>
  </div>

  <label>Calories (kcal)
    <input class="input" type="number" bind:value={calOverride} placeholder={String(autoCal)} />
    <small class="muted">Auto from macros: {autoCal} — leave blank to use it.</small>
  </label>

  <label>Vitamins / notes<input class="input" bind:value={vitamins} placeholder="Iron, B12 (optional)" /></label>

  <label class="check"><input type="checkbox" bind:checked={isJunk} /> Mark as junk</label>

  <div class="actions">
    <button class="btn btn-primary grow" onclick={save}>Save food</button>
    {#if ondelete}<button class="btn btn-danger" onclick={ondelete}>Delete</button>{/if}
  </div>
</div>

<style>
  .form { display: flex; flex-direction: column; gap: 13px; }
  .namerow { display: flex; gap: 12px; align-items: flex-end; }
  .iconwrap { width: 52px; height: 52px; border-radius: var(--radius-md); background: var(--surface-2); border: 1px solid var(--border); display: grid; place-items: center; flex-shrink: 0; }
  .preview { color: var(--muted); display: grid; place-items: center; }
  .two { display: grid; grid-template-columns: 1fr 1fr; gap: 10px; }
  .grid { display: grid; grid-template-columns: 1fr 1fr; gap: 10px; }
  label { display: flex; flex-direction: column; gap: 6px; font-size: 12.5px; font-weight: 650; color: var(--muted); }
  .grow { flex: 1; }
  .check { flex-direction: row; align-items: center; gap: 8px; color: var(--text); }
  .check input { width: auto; }
  .actions { display: flex; gap: 10px; margin-top: 2px; }
  small { font-weight: 500; }
</style>
