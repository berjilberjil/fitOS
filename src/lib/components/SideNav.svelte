<script lang="ts">
  import { page } from '$app/stores';
  import { TABS, isActive } from '$lib/nav';
</script>

<aside class="sidebar">
  <div class="brand">
    <span class="mark">◆</span>
    <span class="word">Luxi<span class="fit">Fit</span></span>
  </div>

  <nav class="links">
    {#each TABS as t}
      <a href={t.href} class="link" class:on={isActive(t.href, $page.url.pathname)}>
        <span class="rail"></span>
        <span class="ico">{t.icon}</span>
        <span class="lbl">{t.label}</span>
      </a>
    {/each}
  </nav>

  <div class="foot">
    <span class="eyebrow">Track · Plan · Build</span>
  </div>
</aside>

<style>
  .sidebar {
    position: sticky; top: 0; height: 100dvh;
    flex-direction: column; gap: 4px;
    padding: 22px 14px; border-right: 1px solid var(--border);
    background: color-mix(in oklab, var(--surface) 55%, var(--bg));
  }
  .brand { display: flex; align-items: center; gap: 9px; padding: 6px 10px 20px; }
  .mark { color: var(--red); font-size: 15px; }
  .word { font-weight: 750; letter-spacing: -0.03em; font-size: 18px; }
  .word .fit { color: var(--red); }

  .links { display: flex; flex-direction: column; gap: 2px; }
  .link {
    position: relative; display: flex; align-items: center; gap: 11px;
    padding: 10px 12px; border-radius: var(--radius-md);
    color: var(--muted); font-weight: 600; font-size: 14px;
    transition: background var(--dur-fast) var(--ease), color var(--dur-fast) var(--ease);
  }
  .link:hover { background: var(--surface-2); color: var(--text); }
  .link.on { color: var(--text); background: var(--surface-2); }
  .ico { font-size: 17px; filter: grayscale(0.4); transition: transform var(--dur) var(--ease); }
  .link:hover .ico, .link.on .ico { transform: translateX(1px); filter: none; }
  .rail {
    position: absolute; left: 0; top: 50%; width: 2.5px; height: 0;
    transform: translateY(-50%); background: var(--red); border-radius: 2px;
    transition: height var(--dur) var(--ease);
  }
  .link:hover .rail { height: 42%; }
  .link.on .rail { height: 62%; }

  .foot { margin-top: auto; padding: 10px 12px; }
</style>
