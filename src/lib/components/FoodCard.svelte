<script lang="ts">
  import type { Food } from '$lib/types';

  let { food, onpick, onedit }: {
    food: Food; onpick?: () => void; onedit?: () => void;
  } = $props();
</script>

<div class="fcard card">
  <button class="main" onclick={onpick}>
    <div class="name">{food.name} {#if food.isJunk}<span class="junk">junk</span>{/if}</div>
    <div class="muted sub">{food.servingLabel} · {food.perServing.calories} kcal</div>
    <div class="macros muted">P {food.perServing.protein} · C {food.perServing.carbs} · Fb {food.perServing.fiber} · F {food.perServing.fats}</div>
    {#if food.vitamins}<div class="vits">💊 {food.vitamins}</div>{/if}
  </button>
  {#if onedit}<button class="edit" onclick={onedit} aria-label="Edit food">✎</button>{/if}
</div>

<style>
  .fcard { padding: 12px; display: flex; align-items: flex-start; gap: 8px; }
  .main { background: none; border: none; text-align: left; color: var(--text); flex: 1; display: flex; flex-direction: column; gap: 4px; }
  .name { font-weight: 700; font-size: 15px; }
  .sub { font-size: 12px; }
  .macros { font-size: 12px; }
  .vits { font-size: 11px; color: #a78bfa; }
  .junk { background: var(--red-dim); color: #fca5a5; font-size: 10px; padding: 1px 6px; border-radius: 6px; margin-left: 4px; }
  .edit { background: var(--surface-2); border: 1px solid #2a2a2e; color: var(--muted); border-radius: 8px; width: 32px; height: 32px; }
</style>
