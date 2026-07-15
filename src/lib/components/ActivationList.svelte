<script lang="ts">
  import type { Exercise } from '$lib/types';
  import { exercises } from '$lib/stores/exercises';
  import { muscleActivation } from '$lib/data/muscle-activation';
  import { exThumb, hasDemo } from '$lib/data/exercise-media';
  import { EXERCISE_FALLBACK } from '$lib/icons';
  import Thumb from './Thumb.svelte';
  import Modal from './Modal.svelte';
  import ExerciseDetail from './ExerciseDetail.svelte';

  let { groupId }: { groupId: string } = $props();

  let demo = $state<Exercise | null>(null);

  const rows = $derived(
    (muscleActivation[groupId] ?? [])
      .map((a) => {
        const ex = $exercises.find((e) => e.name.toLowerCase() === a.name.toLowerCase());
        return ex ? { ex, percent: a.percent } : null;
      })
      .filter((r): r is { ex: Exercise; percent: number } => r !== null)
  );
</script>

{#if rows.length}
  <div class="act">
    <div class="ahead">
      <span class="eyebrow">Best builders</span>
      <span class="hint muted">tap for the demo · ranked by activation</span>
    </div>
    <div class="list">
      {#each rows as r, i (r.ex.id)}
        <button class="row" class:top={i === 0} onclick={() => (demo = r.ex)}>
          <span class="rank num">{i + 1}</span>
          <Thumb src={exThumb(r.ex.id)} fallback={EXERCISE_FALLBACK} size={34} radius={9} alt={r.ex.name} />
          <div class="meta">
            <span class="nm">{r.ex.name}{#if hasDemo(r.ex.id)}<span class="play">▶</span>{/if}</span>
            <div class="barwrap"><span class="bar" style="width:{r.percent}%"></span></div>
          </div>
          <span class="pct num">{r.percent}%</span>
        </button>
      {/each}
    </div>
  </div>
{/if}

<Modal open={!!demo} title={demo?.name ?? ''} onclose={() => (demo = null)}>
  {#if demo}<ExerciseDetail exercise={demo} />{/if}
</Modal>

<style>
  .act { margin-top: 18px; border-top: 1px solid var(--border); padding-top: 16px; }
  .ahead { display: flex; align-items: baseline; justify-content: space-between; gap: 8px; margin-bottom: 10px; }
  .hint { font-size: 10.5px; }
  .list { display: flex; flex-direction: column; gap: 6px; }
  .row {
    display: flex; align-items: center; gap: 10px; text-align: left; width: 100%;
    background: var(--surface-2); border: 1px solid var(--border); border-radius: var(--radius-md);
    padding: 8px 11px; transition: border-color var(--dur-fast) var(--ease), transform var(--dur-fast) var(--ease);
  }
  .row:hover { border-color: var(--red-line); }
  .row:active { transform: scale(0.99); }
  .row.top { border-color: var(--red-line); background: var(--red-soft); }
  .rank { width: 16px; text-align: center; font-size: 12px; font-weight: 800; color: var(--faint); flex-shrink: 0; }
  .row.top .rank { color: var(--red); }
  .meta { flex: 1; min-width: 0; display: flex; flex-direction: column; gap: 5px; }
  .nm { font-weight: 650; font-size: 13.5px; display: flex; align-items: center; gap: 6px; }
  .play { font-size: 8px; color: var(--faint); }
  .barwrap { height: 5px; background: var(--elevated); border-radius: 3px; overflow: hidden; }
  .bar { display: block; height: 100%; background: var(--red); border-radius: 3px; }
  .pct { font-size: 12px; font-weight: 800; color: var(--muted); flex-shrink: 0; width: 34px; text-align: right; }
  .row.top .pct { color: var(--red); }
</style>
