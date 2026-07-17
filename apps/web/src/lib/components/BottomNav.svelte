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
    display: grid; grid-template-columns: repeat(5, 1fr);
    background: color-mix(in oklab, var(--surface) 82%, transparent);
    backdrop-filter: blur(12px);
    border-top: 1px solid var(--border);
  }
  .tab {
    position: relative;
    display: flex; flex-direction: column; align-items: center; justify-content: center;
    gap: 3px; color: var(--muted); font-size: 10.5px; font-weight: 650;
    transition: color 180ms cubic-bezier(0.22, 1, 0.36, 1);
  }
  .ico {
    font-size: 20px; filter: grayscale(0.6) opacity(0.7);
    transition: transform 220ms cubic-bezier(0.34, 1.4, 0.64, 1), filter 180ms ease;
  }
  .tab.on { color: var(--red); }
  .tab.on .ico {
    filter: none;
    transform: translateY(-2px) scale(1.08);
  }
  .tab.on::after {
    content: '';
    position: absolute; bottom: 6px;
    width: 14px; height: 2.5px; border-radius: 99px;
    background: var(--red);
    animation: tabDot 220ms cubic-bezier(0.34, 1.4, 0.64, 1);
  }
  @keyframes tabDot {
    from { transform: scaleX(0.4); opacity: 0; }
    to { transform: scaleX(1); opacity: 1; }
  }
</style>
