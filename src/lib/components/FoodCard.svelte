<script lang="ts">
  import type { Food } from '$lib/types';
  import { foodImage } from '$lib/data/food-images';
  import Thumb from './Thumb.svelte';
  import Icon from './Icon.svelte';

  let { food, onedit }: { food: Food; onedit: () => void } = $props();
</script>

<button class="fcard card card-sm" onclick={onedit}>
  <Thumb src={foodImage(food.id)} emoji={food.icon} size={48} radius={11} alt={food.name} />
  <span class="meta">
    <span class="name">{food.name}{#if food.isJunk}<span class="badge badge-junk">junk</span>{/if}</span>
    <span class="sub muted num">{food.servingLabel} · {food.perServing.calories} kcal</span>
    <span class="macros num muted">P{food.perServing.protein} · C{food.perServing.carbs} · Fb{food.perServing.fiber} · F{food.perServing.fats}</span>
    {#if food.vitamins}<span class="vits"><Icon icon="lucide:pill" size={11} /> {food.vitamins}</span>{/if}
  </span>
  <span class="edit">✎</span>
</button>

<style>
  .fcard {
    display: flex; align-items: flex-start; gap: 12px; text-align: left; width: 100%;
    padding: 12px 13px; transition: border-color var(--dur-fast) var(--ease);
  }
  .fcard:hover { border-color: var(--border-strong); }
  .meta { display: flex; flex-direction: column; gap: 2px; flex: 1; min-width: 0; }
  .name { font-weight: 700; font-size: 14.5px; display: flex; align-items: center; gap: 7px; }
  .sub { font-size: 11.5px; }
  .macros { font-size: 11.5px; }
  .vits { font-size: 11px; color: #b79bff; margin-top: 1px; }
  .edit { color: var(--faint); font-size: 14px; flex-shrink: 0; }
</style>
