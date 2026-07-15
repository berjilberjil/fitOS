<script lang="ts">
  import { page } from '$app/stores';
  import { TABS, isActive } from '$lib/nav';
  import Icon from './Icon.svelte';
  import { navIcon } from '$lib/icons';
</script>

<nav class="bottomnav">
  {#each TABS as t}
    <a href={t.href} class="tab" class:on={isActive(t.href, $page.url.pathname)}>
      <span class="ico"><Icon icon={navIcon(t.href)} size={20} /></span>
      <span class="lbl">{t.label}</span>
    </a>
  {/each}
</nav>

<style>
  .bottomnav {
    position: fixed; left: 0; right: 0; bottom: 0; z-index: 40;
    height: calc(var(--nav-h) + env(safe-area-inset-bottom));
    padding-bottom: env(safe-area-inset-bottom);
    display: grid; grid-template-columns: repeat(4, 1fr);
    background: color-mix(in oklab, var(--surface) 82%, transparent);
    backdrop-filter: blur(12px);
    border-top: 1px solid var(--border);
  }
  .tab {
    display: flex; flex-direction: column; align-items: center; justify-content: center;
    gap: 3px; color: var(--muted); font-size: 10.5px; font-weight: 650;
    transition: color var(--dur-fast) var(--ease);
  }
  .ico { font-size: 20px; filter: grayscale(0.6) opacity(0.7); transition: all var(--dur) var(--ease); }
  .tab.on { color: var(--red); }
  .tab.on .ico { filter: none; transform: translateY(-1px); }
</style>
