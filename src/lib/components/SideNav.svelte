<script lang="ts">
  import { page } from '$app/stores';
  import { TABS, isActive } from '$lib/nav';
  import { currentUser, logout } from '$lib/stores/auth';
  import Icon from './Icon.svelte';
  import { navIcon } from '$lib/icons';
</script>

<aside class="sidebar">
  <div class="brand">
    <img class="logo" src="/logo.png" alt="" />
    <span class="word">fit<span class="fit">OS</span></span>
  </div>

  <nav class="links">
    {#each TABS as t}
      <a href={t.href} class="link" class:on={isActive(t.href, $page.url.pathname)}>
        <span class="rail"></span>
        <span class="ico"><Icon icon={navIcon(t.href)} size={19} /></span>
        <span class="lbl">{t.label}</span>
      </a>
    {/each}
  </nav>

  <div class="foot">
    {#if $currentUser}
      <div class="acct">
        <span class="who">{$currentUser.username}</span>
        <button class="out" onclick={logout}>Log out</button>
      </div>
    {/if}
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
  .logo { width: 26px; height: 26px; object-fit: contain; }
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

  .foot { margin-top: auto; padding: 10px 12px; display: flex; flex-direction: column; gap: 12px; }
  .acct { display: flex; align-items: center; justify-content: space-between; gap: 8px; }
  .who { font-size: 13px; font-weight: 650; color: var(--text); overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
  .out { background: var(--surface-2); border: 1px solid var(--border); color: var(--muted); border-radius: var(--pill); padding: 5px 11px; font-size: 11.5px; font-weight: 650; flex-shrink: 0; }
  .out:hover { color: var(--text); }
</style>
