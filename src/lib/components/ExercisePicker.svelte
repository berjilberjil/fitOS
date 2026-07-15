<script lang="ts">
  import { exercises } from '$lib/stores/exercises';
  import type { WorkoutCategory } from '$lib/types';
  import { WORKOUT_CATEGORIES } from '$lib/data/workouts';
  import { exThumb } from '$lib/data/exercise-media';
  import { EXERCISE_FALLBACK } from '$lib/icons';
  import Thumb from './Thumb.svelte';

  let { onpick }: { onpick: (exerciseId: string) => void } = $props();

  const filters: (WorkoutCategory | 'all')[] = ['all', ...WORKOUT_CATEGORIES.map((c) => c.key)];
  let query = $state('');
  let filter = $state<WorkoutCategory | 'all'>('all');

  const label = (k: WorkoutCategory | 'all') =>
    k === 'all' ? 'All' : (WORKOUT_CATEGORIES.find((c) => c.key === k)?.label ?? k);

  const results = $derived(
    $exercises.filter((e) => {
      const q = e.name.toLowerCase().includes(query.toLowerCase());
      const c = filter === 'all' ? true : e.category === filter;
      return q && c;
    })
  );
</script>

<input class="input" placeholder="Search exercises…" bind:value={query} />
<div class="chips">
  {#each filters as f}
    <button class="chip" class:on={f === filter} onclick={() => (filter = f)}>{label(f)}</button>
  {/each}
</div>
<div class="grid">
  {#each results as e (e.id)}
    <button class="pick" onclick={() => onpick(e.id)}>
      <Thumb src={exThumb(e.id)} fallback={EXERCISE_FALLBACK} size={34} radius={9} alt={e.name} />
      <span class="meta">
        <span class="nm">{e.name}</span>
        <span class="sub muted">{e.equipment} · {e.primary}</span>
      </span>
    </button>
  {/each}
  {#if results.length === 0}<p class="muted empty">No matches.</p>{/if}
</div>

<style>
  .chips { display: flex; gap: 6px; overflow-x: auto; margin: 12px 0; padding-bottom: 2px; }
  .grid { display: flex; flex-direction: column; gap: 6px; max-height: 52dvh; overflow-y: auto; }
  .pick {
    display: flex; align-items: center; gap: 12px; text-align: left;
    background: var(--surface-2); border: 1px solid var(--border);
    border-radius: var(--radius-md); padding: 10px 12px;
    transition: border-color var(--dur-fast) var(--ease), background var(--dur-fast) var(--ease);
  }
  .pick:hover { border-color: var(--red-line); background: var(--elevated); }
  .meta { display: flex; flex-direction: column; gap: 1px; flex: 1; min-width: 0; }
  .nm { font-weight: 650; font-size: 14px; }
  .sub { font-size: 11.5px; }
  .empty { padding: 20px; text-align: center; }
</style>
