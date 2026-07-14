<script lang="ts">
  import { page } from '$app/stores';

  const tabs = [
    { href: '/food', label: 'Food', icon: '🍽️' },
    { href: '/progress', label: 'Progress', icon: '📈' },
    { href: '/workout', label: 'Workout', icon: '🏋️' },
    { href: '/anatomy', label: 'Anatomy', icon: '🫀' }
  ];
  const active = (href: string, path: string) => path.startsWith(href);
</script>

<nav class="nav">
  {#each tabs as t}
    <a href={t.href} class="tab" class:active={active(t.href, $page.url.pathname)}>
      <span class="icon">{t.icon}</span>
      <span class="lbl">{t.label}</span>
    </a>
  {/each}
</nav>

<style>
  .nav {
    position: fixed; left: 0; right: 0; bottom: 0;
    height: calc(var(--nav-h) + env(safe-area-inset-bottom));
    padding-bottom: env(safe-area-inset-bottom);
    max-width: var(--maxw); margin: 0 auto;
    display: grid; grid-template-columns: repeat(4, 1fr);
    background: var(--surface); border-top: 1px solid #232327;
  }
  .tab {
    display: flex; flex-direction: column; align-items: center; justify-content: center;
    gap: 2px; color: var(--muted); font-size: 11px; font-weight: 600;
  }
  .tab.active { color: var(--red); }
  .icon { font-size: 20px; filter: grayscale(1) brightness(1.6); }
  .tab.active .icon { filter: none; }
</style>
