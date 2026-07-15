<script lang="ts">
  import '../app.css';
  import { onMount } from 'svelte';
  import type { Snippet } from 'svelte';
  import SideNav from '$lib/components/SideNav.svelte';
  import BottomNav from '$lib/components/BottomNav.svelte';
  import AuthGate from '$lib/components/AuthGate.svelte';
  import { currentUser, authReady, initAuth, logout } from '$lib/stores/auth';

  let { children }: { children: Snippet } = $props();

  onMount(() => {
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
        <span class="mb-brand">Luxi<span class="fit">Fit</span></span>
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
    padding: 12px 16px calc(12px + env(safe-area-inset-top));
    border-bottom: 1px solid var(--border);
  }
  .mb-brand { font-weight: 750; letter-spacing: -0.03em; font-size: 16px; }
  .mb-brand .fit { color: var(--red); }
  .mb-out {
    background: var(--surface-2); border: 1px solid var(--border); color: var(--muted);
    border-radius: var(--pill); padding: 6px 12px; font-size: 12px; font-weight: 650;
  }
  .mb-out:hover { color: var(--text); }
  @media (min-width: 860px) { .mobilebar { display: none; } }
</style>
