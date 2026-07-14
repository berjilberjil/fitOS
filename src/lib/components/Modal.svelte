<script lang="ts">
  import type { Snippet } from 'svelte';

  let { open = false, title = '', onclose, children }: {
    open?: boolean; title?: string; onclose: () => void; children: Snippet;
  } = $props();
</script>

{#if open}
  <div class="backdrop" onclick={onclose} role="presentation">
    <div class="sheet" onclick={(e) => e.stopPropagation()} role="dialog" aria-modal="true">
      <div class="sheet-head">
        <h2 class="h2">{title}</h2>
        <button class="x" onclick={onclose} aria-label="Close">✕</button>
      </div>
      <div class="sheet-body">
        {@render children()}
      </div>
    </div>
  </div>
{/if}

<style>
  .backdrop {
    position: fixed; inset: 0; background: rgba(0,0,0,0.6);
    display: flex; align-items: flex-end; justify-content: center; z-index: 50;
  }
  .sheet {
    background: var(--surface); width: 100%; max-width: var(--maxw);
    border-radius: 20px 20px 0 0; border: 1px solid #232327;
    max-height: 88dvh; display: flex; flex-direction: column;
  }
  .sheet-head {
    display: flex; align-items: center; justify-content: space-between;
    padding: 16px; border-bottom: 1px solid #232327;
  }
  .sheet-body { padding: 16px; overflow-y: auto; }
  .x { background: none; border: none; color: var(--muted); font-size: 18px; }
</style>
