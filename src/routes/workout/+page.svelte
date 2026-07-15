<script lang="ts">
  import SegmentedControl from '$lib/components/SegmentedControl.svelte';
  import WorkoutTodayView from '$lib/components/WorkoutTodayView.svelte';
  import WorkoutPlanView from '$lib/components/WorkoutPlanView.svelte';
  import WorkoutCatalogView from '$lib/components/WorkoutCatalogView.svelte';

  let segment = $state('Today');
  const segments = ['Today', 'Plan', 'Workouts'];
</script>

<header class="pagehead">
  <span class="eyebrow">Training</span>
  <h1 class="h1">Workout</h1>
</header>

<div class="seg"><SegmentedControl options={segments} value={segment} onchange={(v) => (segment = v)} /></div>

{#key segment}
  <div class="view rise">
    {#if segment === 'Today'}<WorkoutTodayView />
    {:else if segment === 'Plan'}<WorkoutPlanView />
    {:else}<WorkoutCatalogView />{/if}
  </div>
{/key}

<style>
  .pagehead { margin-bottom: 14px; }
  .pagehead .eyebrow { display: block; margin-bottom: 3px; }
  .seg { margin-bottom: 16px; }
</style>
