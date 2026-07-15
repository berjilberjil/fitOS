<script lang="ts">
  import type { Food } from '$lib/types';
  import type { MealDef } from '$lib/data/meals';
  import FoodRow from './FoodRow.svelte';
  import Icon from './Icon.svelte';
  import { mealIcon } from '$lib/icons';

  interface Row { food: Food; quantity: number; index: number; plannedHint?: number; }

  let { meal, rows, kcal, onqty, onswap, onremove, onadd }: {
    meal: MealDef;
    rows: Row[];
    kcal: number;
    onqty: (index: number, v: number) => void;
    onswap: (index: number) => void;
    onremove: (index: number) => void;
    onadd: () => void;
  } = $props();
</script>

<section class="meal card">
  <header class="head">
    <span class="ic"><Icon icon={mealIcon(meal.key)} size={17} /></span>
    <span class="ttl">{meal.label}</span>
    {#if kcal > 0}<span class="kcal num">{kcal} kcal</span>{/if}
  </header>

  {#if rows.length}
    <div class="rows">
      {#each rows as r (r.index)}
        <FoodRow
          food={r.food}
          quantity={r.quantity}
          plannedHint={r.plannedHint}
          onqty={(v) => onqty(r.index, v)}
          onswap={() => onswap(r.index)}
          onremove={() => onremove(r.index)}
        />
      {/each}
    </div>
  {:else}
    <p class="empty muted">Nothing here yet.</p>
  {/if}

  <button class="add" onclick={onadd}>＋ Add food</button>
</section>

<style>
  .meal { padding: 14px 15px; }
  .head { display: flex; align-items: center; gap: 9px; margin-bottom: 4px; }
  .ic { font-size: 17px; }
  .ttl { font-weight: 700; font-size: 15px; letter-spacing: -0.01em; }
  .kcal { margin-left: auto; font-size: 12px; font-weight: 650; color: var(--muted); }
  .rows { margin: 4px 0; }
  .empty { font-size: 13px; padding: 8px 4px; }
  .add {
    width: 100%; margin-top: 8px; padding: 9px; border-radius: var(--radius-sm);
    background: transparent; border: 1px dashed var(--border-strong); color: var(--muted);
    font-weight: 600; font-size: 13px; transition: all var(--dur-fast) var(--ease);
  }
  .add:hover { color: var(--text); border-color: var(--red-line); background: var(--red-soft); }
</style>
