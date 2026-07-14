<script lang="ts">
  import '../app.css';
  import type { Snippet } from 'svelte';
  import BottomNav from '$lib/components/BottomNav.svelte';

  let { children }: { children: Snippet } = $props();
</script>

<div class="app-shell">
  {@render children()}
  <BottomNav />
</div>
