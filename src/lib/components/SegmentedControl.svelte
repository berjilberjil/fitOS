<script lang="ts">
  let { options, value, onchange }: {
    options: string[]; value: string; onchange: (v: string) => void;
  } = $props();
</script>

<div class="seg">
  {#each options as o}
    <button class="opt" class:active={o === value} onclick={() => onchange(o)}>{o}</button>
  {/each}
</div>

<style>
  .seg { display: grid; grid-auto-flow: column; gap: 4px; background: var(--surface-2); padding: 4px; border-radius: 12px; }
  .opt { background: none; border: none; color: var(--muted); padding: 10px; border-radius: 9px; font-weight: 600; font-size: 14px; }
  .opt.active { background: var(--red); color: #fff; }
</style>
