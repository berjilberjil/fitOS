<script lang="ts">
  import { foods } from '$lib/stores/foods';
  import type { Food, Category } from '$lib/types';
  import { foodImage } from '$lib/data/food-images';
  import Thumb from './Thumb.svelte';

  let { onpick, askQuantity = true }: {
    onpick: (foodId: string, quantity: number) => void;
    askQuantity?: boolean;
  } = $props();

  const filters: (Category | 'all')[] = ['all', 'protein', 'carb', 'veg', 'dairy', 'fruit', 'drink', 'junk', 'other'];
  let query = $state('');
  let filter = $state<Category | 'all'>('all');
  let selected = $state<Food | null>(null);
  let quantity = $state(1);

  const results = $derived(
    $foods.filter((f) => {
      const q = f.name.toLowerCase().includes(query.toLowerCase());
      const c = filter === 'all' ? true : filter === 'junk' ? f.isJunk : f.category === filter;
      return q && c;
    })
  );

  function choose(f: Food) {
    if (askQuantity) {
      selected = f;
      quantity = 1;
    } else {
      onpick(f.id, 1);
    }
  }
</script>

{#if !selected}
  <input class="input" placeholder="Search foods…" bind:value={query} />
  <div class="chips">
    {#each filters as f}
      <button class="chip" class:on={f === filter} onclick={() => (filter = f)}>{f}</button>
    {/each}
  </div>
  <div class="grid">
    {#each results as f (f.id)}
      <button class="pick" onclick={() => choose(f)}>
        <Thumb src={foodImage(f.id)} emoji={f.icon} size={34} radius={9} alt={f.name} />
        <span class="meta">
          <span class="nm">{f.name}</span>
          <span class="sub muted num">{f.servingLabel} · {f.perServing.calories} kcal</span>
        </span>
        {#if f.isJunk}<span class="badge badge-junk">junk</span>{/if}
      </button>
    {/each}
    {#if results.length === 0}<p class="muted empty">No matches.</p>{/if}
  </div>
{:else}
  <div class="qty">
    <div class="chosen">
      <Thumb src={foodImage(selected.id)} emoji={selected.icon} size={52} radius={13} alt={selected.name} />
      <div>
        <div class="h2">{selected.name}</div>
        <p class="muted num">{selected.servingLabel} · {selected.perServing.calories} kcal each</p>
      </div>
    </div>
    <label class="lab">How many servings?
      <input class="input" type="number" min="0.25" step="0.25" bind:value={quantity} />
    </label>
    <div class="actions">
      <button class="btn btn-outline" onclick={() => (selected = null)}>Back</button>
      <button class="btn btn-primary grow" onclick={() => onpick(selected!.id, quantity)}>Add</button>
    </div>
  </div>
{/if}

<style>
  .chips { display: flex; gap: 6px; overflow-x: auto; margin: 12px 0; padding-bottom: 2px; }
  .grid { display: flex; flex-direction: column; gap: 6px; max-height: 52dvh; overflow-y: auto; }
  .pick {
    display: flex; align-items: center; gap: 12px; text-align: left;
    background: var(--surface-2); border: 1px solid var(--border);
    border-radius: var(--radius-md); padding: 10px 12px;
    transition: border-color var(--dur-fast) var(--ease), background var(--dur-fast) var(--ease);
  }
  .pick:hover { border-color: var(--red-line); background: var(--elevated); }
  .meta { display: flex; flex-direction: column; gap: 1px; flex: 1; min-width: 0; }
  .nm { font-weight: 650; font-size: 14px; }
  .sub { font-size: 11.5px; }
  .empty { padding: 20px; text-align: center; }

  .qty { display: flex; flex-direction: column; gap: 16px; }
  .chosen { display: flex; align-items: center; gap: 14px; }
  .lab { display: flex; flex-direction: column; gap: 8px; font-size: 13px; font-weight: 650; color: var(--muted); }
  .actions { display: flex; gap: 10px; }
  .grow { flex: 1; }
</style>
