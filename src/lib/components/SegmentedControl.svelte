<script lang="ts">
  let { options, value, onchange }: {
    options: string[]; value: string; onchange: (v: string) => void;
  } = $props();
</script>

<div class="seg">
  {#each options as o}
    <button class="opt" class:on={o === value} onclick={() => onchange(o)}>{o}</button>
  {/each}
</div>

<style>
  .seg {
    display: grid; grid-auto-flow: column; grid-auto-columns: 1fr; gap: 3px;
    background: var(--surface-2); padding: 4px; border-radius: var(--pill);
    border: 1px solid var(--border);
  }
  .opt {
    background: none; border: none; color: var(--muted);
    padding: 9px; border-radius: var(--pill); font-weight: 650; font-size: 13px;
    transition: all var(--dur-fast) var(--ease);
  }
  .opt:hover { color: var(--text); }
  .opt.on { background: var(--red); color: #fff; }
</style>
