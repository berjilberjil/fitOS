<script lang="ts">
  import type { Food } from '$lib/types';
  import { scaleMacros } from '$lib/utils/nutrition';
  import Stepper from './Stepper.svelte';

  let { food, quantity, plannedHint, onqty, onswap, onremove }: {
    food: Food;
    quantity: number;
    plannedHint?: number;
    onqty: (v: number) => void;
    onswap: () => void;
    onremove: () => void;
  } = $props();

  const m = $derived(scaleMacros(food.perServing, quantity));
</script>

<div class="row" class:dim={quantity === 0}>
  <span class="ico">{food.icon}</span>
  <div class="meta">
    <div class="nm">
      {food.name}
      {#if plannedHint !== undefined && plannedHint !== quantity}
        <span class="hint">plan {plannedHint}</span>
      {/if}
    </div>
    <div class="macros num muted">{m.calories} kcal · P{m.protein} · C{m.carbs} · F{m.fats}</div>
  </div>
  <button class="mini" onclick={onswap} aria-label="Swap food" title="Swap">⇄</button>
  <button class="mini" onclick={onremove} aria-label="Remove food" title="Remove">✕</button>
  <Stepper value={quantity} onchange={onqty} />
</div>

<style>
  .row {
    display: flex; align-items: center; gap: 9px;
    padding: 9px 4px; border-bottom: 1px solid var(--border);
  }
  .row:last-child { border-bottom: none; }
  .dim { opacity: 0.5; }
  .ico { font-size: 23px; width: 28px; text-align: center; flex-shrink: 0; }
  .meta { flex: 1; min-width: 0; }
  .nm { font-weight: 650; font-size: 14px; display: flex; align-items: center; gap: 7px; }
  .hint { font-size: 10px; font-weight: 700; color: var(--faint); background: var(--surface-2); padding: 1px 6px; border-radius: var(--pill); }
  .macros { font-size: 11px; margin-top: 1px; }
  .mini {
    width: 26px; height: 26px; border-radius: var(--pill); flex-shrink: 0;
    background: transparent; border: 1px solid transparent; color: var(--faint); font-size: 13px;
    display: grid; place-items: center; transition: all var(--dur-fast) var(--ease);
  }
  .mini:hover { color: var(--text); background: var(--surface-2); }
</style>
