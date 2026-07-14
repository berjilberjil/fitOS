<script lang="ts">
  import { foods } from '$lib/stores/foods';
  import FoodCard from './FoodCard.svelte';
  import type { Food } from '$lib/types';

  let { onadd }: { onadd: (foodId: string, quantity: number) => void } = $props();

  let query = $state('');
  let selected = $state<Food | null>(null);
  let quantity = $state(1);

  const results = $derived(
    $foods.filter((f) => f.name.toLowerCase().includes(query.toLowerCase()))
  );

  function confirm() {
    if (selected && quantity > 0) onadd(selected.id, quantity);
  }
</script>

{#if !selected}
  <input class="search" placeholder="Search foods…" bind:value={query} />
  <div class="list">
    {#each results as f (f.id)}
      <FoodCard food={f} onpick={() => (selected = f)} />
    {/each}
    {#if results.length === 0}<p class="muted">No matches.</p>{/if}
  </div>
{:else}
  <div class="qty">
    <div class="h2">{selected.name}</div>
    <p class="muted">{selected.servingLabel} · {selected.perServing.calories} kcal each</p>
    <label>Quantity (servings)
      <input type="number" min="0.25" step="0.25" bind:value={quantity} />
    </label>
    <div class="actions">
      <button class="btn-ghost" onclick={() => (selected = null)}>Back</button>
      <button class="btn-primary" onclick={confirm}>Add to today</button>
    </div>
  </div>
{/if}

<style>
  .search { width: 100%; background: var(--surface-2); color: var(--text); border: 1px solid #2a2a2e; border-radius: 10px; padding: 12px; font-size: 16px; margin-bottom: 12px; }
  .list { display: flex; flex-direction: column; gap: 8px; }
  .qty { display: flex; flex-direction: column; gap: 12px; }
  label { display: flex; flex-direction: column; gap: 6px; font-size: 13px; font-weight: 600; color: var(--muted); }
  .qty input { background: var(--surface-2); color: var(--text); border: 1px solid #2a2a2e; border-radius: 10px; padding: 12px; font-size: 16px; }
  .actions { display: flex; gap: 10px; }
  .actions .btn-primary { flex: 1; }
</style>
