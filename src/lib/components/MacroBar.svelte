<script lang="ts">
  let { label, value, goal, unit, color = 'var(--red)' }: {
    label: string; value: number; goal?: number; unit: string; color?: string;
  } = $props();

  const pct = $derived(goal && goal > 0 ? Math.min((value / goal) * 100, 100) : 0);
</script>

<div class="row">
  <div class="top">
    <span>{label}</span>
    <span class="muted">{value}{goal ? ` / ${goal}` : ''} {unit}</span>
  </div>
  {#if goal}
    <div class="track"><div class="fill" style="width:{pct}%; background:{color}"></div></div>
  {/if}
</div>

<style>
  .row { display: flex; flex-direction: column; gap: 6px; }
  .top { display: flex; justify-content: space-between; font-size: 13px; font-weight: 600; }
  .track { height: 8px; background: var(--surface-2); border-radius: 6px; overflow: hidden; }
  .fill { height: 100%; border-radius: 6px; transition: width 0.25s ease; }
</style>
