<script lang="ts">
  import { foods, addFood, updateFood, deleteFood } from '$lib/stores/foods';
  import type { Food, Category } from '$lib/types';
  import FoodCard from './FoodCard.svelte';
  import FoodForm from './FoodForm.svelte';
  import Modal from './Modal.svelte';
  import Fab from './Fab.svelte';

  const filters: (Category | 'all')[] = ['all', 'protein', 'carb', 'veg', 'dairy', 'fruit', 'drink', 'junk', 'other'];
  let filter = $state<Category | 'all'>('all');
  let query = $state('');
  let editing = $state<Food | null>(null);
  let creating = $state(false);

  const shown = $derived(
    $foods.filter((f) => {
      const matchQ = f.name.toLowerCase().includes(query.toLowerCase());
      const matchF = filter === 'all' ? true : filter === 'junk' ? f.isJunk : f.category === filter;
      return matchQ && matchF;
    })
  );
</script>

<input class="search" placeholder="Search foods…" bind:value={query} />
<div class="chips">
  {#each filters as f}
    <button class="chip" class:active={f === filter} onclick={() => (filter = f)}>{f}</button>
  {/each}
</div>

<div class="list">
  {#each shown as f (f.id)}
    <FoodCard food={f} onedit={() => (editing = f)} />
  {/each}
</div>

<Fab onclick={() => (creating = true)} />

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
  .search { width: 100%; background: var(--surface-2); color: var(--text); border: 1px solid #2a2a2e; border-radius: 10px; padding: 12px; font-size: 16px; margin-bottom: 12px; }
  .chips { display: flex; gap: 6px; overflow-x: auto; padding-bottom: 12px; }
  .chip { background: var(--surface-2); border: 1px solid #2a2a2e; color: var(--muted); border-radius: 999px; padding: 6px 12px; font-size: 12px; font-weight: 600; white-space: nowrap; text-transform: capitalize; }
  .chip.active { background: var(--red); color: #fff; border-color: var(--red); }
  .list { display: flex; flex-direction: column; gap: 8px; padding-bottom: 90px; }
</style>
