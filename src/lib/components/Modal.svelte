<script lang="ts">
  import type { Snippet } from 'svelte';

  let { open = false, title = '', onclose, children }: {
    open?: boolean; title?: string; onclose: () => void; children: Snippet;
  } = $props();
</script>

{#if open}
  <div class="backdrop" onclick={onclose} role="presentation">
    <div class="sheet rise" onclick={(e) => e.stopPropagation()} role="dialog" aria-modal="true">
      <div class="grip"></div>
      <div class="head">
        <h2 class="h2">{title}</h2>
        <button class="icon-btn" onclick={onclose} aria-label="Close">✕</button>
      </div>
      <div class="body">
        {@render children()}
      </div>
    </div>
  </div>
{/if}

<style>
  .backdrop {
    position: fixed; inset: 0; z-index: 60;
    background: rgba(0, 0, 0, 0.55); backdrop-filter: blur(3px);
    display: flex; align-items: flex-end; justify-content: center;
  }
  .sheet {
    background: var(--surface); width: 100%; max-width: 520px;
    border: 1px solid var(--border-strong); border-bottom: none;
    border-radius: 26px 26px 0 0; max-height: 90dvh;
    display: flex; flex-direction: column;
  }
  .grip { width: 38px; height: 4px; border-radius: 3px; background: var(--border-strong); margin: 10px auto 2px; }
  .head { display: flex; align-items: center; justify-content: space-between; padding: 8px 18px 14px; }
  .body { padding: 4px 18px 22px; overflow-y: auto; }

  @media (min-width: 860px) {
    .backdrop { align-items: center; }
    .sheet { border-radius: 24px; border-bottom: 1px solid var(--border-strong); max-height: 84dvh; }
    .grip { display: none; }
    .head { padding-top: 18px; }
  }
</style>
