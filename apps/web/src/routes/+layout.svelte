<script lang="ts">
  import '../app.css';
  import { onMount } from 'svelte';
  import type { Snippet } from 'svelte';
  import SideNav from '$lib/components/SideNav.svelte';
  import BottomNav from '$lib/components/BottomNav.svelte';
  import AuthGate from '$lib/components/AuthGate.svelte';
  import { currentUser, authReady, initAuth, logout } from '$lib/stores/auth';
  import { theme } from '$lib/stores/theme';

  let { children }: { children: Snippet } = $props();

  onMount(() => {
    // Apply stored theme ASAP (store also applies on subscribe in browser).
    document.documentElement.setAttribute('data-theme', $theme);
    initAuth();
  });
</script>

{#if !$authReady}
  <div class="boot"><span class="spin"></span></div>
{:else if !$currentUser}
  <AuthGate />
{:else}
  <div class="frame">
    <SideNav />
    <main class="main">
      <header class="mobilebar">
        <span class="mb-brand"><img class="mb-logo" src="/logo.png" alt="" /> fit<span class="fit">OS</span></span>
        <button class="mb-out" onclick={logout}>{$currentUser.username} · Log out</button>
      </header>
      <div class="content">
        {@render children()}
      </div>
    </main>
    <BottomNav />
  </div>
{/if}

<style>
  .boot { min-height: 100dvh; display: grid; place-items: center; }
  .spin {
    width: 30px; height: 30px; border-radius: 50%;
    border: 3px solid var(--surface-2); border-top-color: var(--red);
    animation: spin 0.8s linear infinite;
  }
  @keyframes spin { to { transform: rotate(360deg); } }

  .mobilebar {
    display: flex; align-items: center; justify-content: space-between;
    /* safe-area MUST be on the TOP so the header clears the status bar / notch */
    padding: calc(10px + env(safe-area-inset-top)) 16px 10px;
    border-bottom: 1px solid var(--border);
    position: sticky; top: 0; z-index: 30;
    background: color-mix(in oklab, var(--bg) 82%, transparent);
    backdrop-filter: blur(12px);
  }
  .mb-brand { display: inline-flex; align-items: center; gap: 7px; font-weight: 750; letter-spacing: -0.03em; font-size: 16px; }
  .mb-brand .mb-logo { width: 22px; height: 22px; object-fit: contain; }
  .mb-brand .fit { color: var(--red); }
  .mb-out {
    background: var(--surface-2); border: 1px solid var(--border); color: var(--muted);
    border-radius: var(--pill); padding: 6px 12px; font-size: 12px; font-weight: 650;
  }
  .mb-out:hover { color: var(--text); }
  @media (min-width: 860px) { .mobilebar { display: none; } }
</style>
