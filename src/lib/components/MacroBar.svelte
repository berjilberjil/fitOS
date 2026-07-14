<script lang="ts">
  let { label, value, goal, unit, color = 'var(--red)' }: {
    label: string; value: number; goal?: number; unit: string; color?: string;
  } = $props();

  const pct = $derived(goal && goal > 0 ? Math.min((value / goal) * 100, 100) : 0);
</script>

<div class="row">
  <div class="top">
    <span class="lbl">{label}</span>
    <span class="val num">{value}<span class="muted">{goal ? ` / ${goal}` : ''} {unit}</span></span>
  </div>
  {#if goal}
    <div class="track"><div class="fill" style="width:{pct}%; background:{color}"></div></div>
  {/if}
</div>

<style>
  .row { display: flex; flex-direction: column; gap: 7px; }
  .top { display: flex; justify-content: space-between; align-items: baseline; font-size: 13px; }
  .lbl { font-weight: 650; }
  .val { font-weight: 700; }
  .val .muted { font-weight: 500; font-size: 12px; }
  .track { height: 7px; background: var(--surface-2); border-radius: 6px; overflow: hidden; }
  .fill { height: 100%; border-radius: 6px; transition: width var(--dur-slow) var(--ease); }
</style>
