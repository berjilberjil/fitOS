<script lang="ts">
  import '../app.css';
  import type { Snippet } from 'svelte';
  import SideNav from '$lib/components/SideNav.svelte';
  import BottomNav from '$lib/components/BottomNav.svelte';

  let { children }: { children: Snippet } = $props();
</script>

<div class="frame">
  <SideNav />
  <main class="main">
    <div class="content">
      {@render children()}
    </div>
  </main>
  <BottomNav />
</div>
