<script lang="ts">
  import { foods, addFood, updateFood, deleteFood } from '$lib/stores/foods';
  import type { Food, Category } from '$lib/types';
  import FoodCard from './FoodCard.svelte';
  import FoodForm from './FoodForm.svelte';
  import Modal from './Modal.svelte';

  const filters: (Category | 'all')[] = ['all', 'protein', 'carb', 'veg', 'dairy', 'fruit', 'drink', 'junk', 'other'];
  let filter = $state<Category | 'all'>('all');
  let query = $state('');
  let editing = $state<Food | null>(null);
  let creating = $state(false);

  const shown = $derived(
    $foods.filter((f) => {
      const q = f.name.toLowerCase().includes(query.toLowerCase());
      const c = filter === 'all' ? true : filter === 'junk' ? f.isJunk : f.category === filter;
      return q && c;
    })
  );
</script>

<div class="toolbar">
  <input class="input" placeholder="Search foods…" bind:value={query} />
  <button class="btn btn-primary new" onclick={() => (creating = true)}>＋ New</button>
</div>

<div class="chips">
  {#each filters as f}
    <button class="chip" class:on={f === filter} onclick={() => (filter = f)}>{f}</button>
  {/each}
</div>

<p class="count muted num">{shown.length} foods</p>

<div class="grid stagger">
  {#each shown as f (f.id)}
    <FoodCard food={f} onedit={() => (editing = f)} />
  {/each}
</div>

<Modal open={creating} title="Add food" onclose={() => (creating = false)}>
  <FoodForm onsave={(d) => { addFood(d); creating = false; }} />
</Modal>

<Modal open={!!editing} title="Edit food" onclose={() => (editing = null)}>
  {#if editing}
    <FoodForm
      initial={editing}
      onsave={(d) => { updateFood({ ...editing!, ...d }); editing = null; }}
      ondelete={() => { deleteFood(editing!.id); editing = null; }}
    />
  {/if}
</Modal>

<style>
  .toolbar { display: flex; gap: 10px; align-items: stretch; }
  .toolbar .input { flex: 1; }
  .new { flex-shrink: 0; }
  .chips { display: flex; gap: 6px; overflow-x: auto; padding: 12px 0 4px; }
  .count { font-size: 12px; margin: 4px 0 10px; }
  .grid { display: grid; grid-template-columns: 1fr; gap: 8px; }
  @media (min-width: 620px) { .grid { grid-template-columns: 1fr 1fr; } }
</style>
