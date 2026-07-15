<script lang="ts">
  import type { Exercise } from '$lib/types';
  import Stepper from './Stepper.svelte';
  import Thumb from './Thumb.svelte';
  import { WEIGHT_STEP } from '$lib/data/workouts';
  import { exThumb } from '$lib/data/exercise-media';
  import { EXERCISE_FALLBACK } from '$lib/icons';

  let {
    exercise, mode, sets, reps,
    weightKg = 0, done = false, lastWeight = undefined,
    onsets, onreps, onweight, ondone, onswap, onremove, onshowdemo
  }: {
    exercise: Exercise;
    mode: 'plan' | 'log';
    sets: number;
    reps: number;
    weightKg?: number;
    done?: boolean;
    lastWeight?: number;
    onsets?: (v: number) => void;
    onreps?: (v: number) => void;
    onweight?: (v: number) => void;
    ondone?: () => void;
    onswap?: () => void;
    onremove: () => void;
    onshowdemo?: () => void;
  } = $props();

  const delta = $derived(
    lastWeight !== undefined && weightKg > 0 ? Math.round((weightKg - lastWeight) * 100) / 100 : 0
  );
</script>

<div class="row" class:done={mode === 'log' && done}>
  {#if onshowdemo}
    <button class="icobtn" onclick={onshowdemo} aria-label="See {exercise.name} demo" title="See demo">
      <Thumb src={exThumb(exercise.id)} fallback={EXERCISE_FALLBACK} size={34} radius={9} alt={exercise.name} />
    </button>
  {:else}
    <Thumb src={exThumb(exercise.id)} fallback={EXERCISE_FALLBACK} size={34} radius={9} alt={exercise.name} />
  {/if}

  <div class="meta">
    <div class="nm">{exercise.name}</div>
    <div class="sub muted">
      {exercise.primary}
      {#if mode === 'log'}· {sets} × {reps}{/if}
    </div>
  </div>

  {#if mode === 'plan'}
    <div class="sr">
      <div class="srcol">
        <span class="srl">Sets</span>
        <Stepper value={sets} onchange={(v) => onsets?.(v)} />
      </div>
      <div class="srcol">
        <span class="srl">Reps</span>
        <Stepper value={reps} onchange={(v) => onreps?.(v)} />
      </div>
    </div>
    <button class="mini" onclick={onremove} aria-label="Remove exercise" title="Remove">✕</button>
  {:else}
    <div class="logside">
      {#if exercise.weighted}
        <div class="wt">
          {#if lastWeight !== undefined}
            <span class="last num">last {lastWeight}kg</span>
          {:else}
            <span class="last num faintier">new</span>
          {/if}
          <Stepper value={weightKg} step={WEIGHT_STEP} suffix=" kg" onchange={(v) => onweight?.(v)} />
          {#if delta !== 0}
            <span class="delta num" class:up={delta > 0} class:down={delta < 0}>
              {delta > 0 ? '▲' : '▼'} {delta > 0 ? '+' : ''}{delta}
            </span>
          {/if}
        </div>
      {:else}
        <span class="bw num">{sets} × {reps}</span>
      {/if}
      <div class="acts">
        <button class="mini" onclick={onswap} aria-label="Swap exercise" title="Swap">⇄</button>
        <button class="mini" onclick={onremove} aria-label="Remove exercise" title="Remove">✕</button>
        <button class="check" class:on={done} onclick={ondone} aria-label="Mark done" title="Done">
          {done ? '✓' : ''}
        </button>
      </div>
    </div>
  {/if}
</div>

<style>
  .row { display: flex; align-items: center; gap: 10px; padding: 11px 4px; border-bottom: 1px solid var(--border); }
  .row:last-child { border-bottom: none; }
  .row.done { opacity: 0.55; }
  .icobtn {
    padding: 0; border: none; background: none; flex-shrink: 0; border-radius: 9px;
    line-height: 0; transition: transform var(--dur-fast) var(--ease);
  }
  .icobtn:hover { transform: scale(1.06); }
  .icobtn:active { transform: scale(0.94); }
  .meta { flex: 1; min-width: 0; }
  .nm { font-weight: 650; font-size: 14px; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
  .sub { font-size: 11.5px; margin-top: 1px; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }

  /* plan mode */
  .sr { display: flex; gap: 10px; }
  .srcol { display: flex; flex-direction: column; align-items: center; gap: 3px; }
  .srl { font-size: 9px; font-weight: 700; letter-spacing: 0.06em; text-transform: uppercase; color: var(--faint); }

  /* log mode */
  .logside { display: flex; flex-direction: column; align-items: flex-end; gap: 6px; }
  .wt { display: flex; align-items: center; gap: 8px; }
  .last { font-size: 10.5px; font-weight: 700; color: var(--faint); white-space: nowrap; }
  .faintier { opacity: 0.7; }
  .delta { font-size: 10.5px; font-weight: 800; white-space: nowrap; }
  .delta.up { color: var(--ok); }
  .delta.down { color: var(--red-bright); }
  .bw { font-size: 13px; font-weight: 700; color: var(--muted); }
  .acts { display: flex; align-items: center; gap: 4px; }
  .check {
    width: 26px; height: 26px; border-radius: var(--pill); flex-shrink: 0;
    background: var(--surface-2); border: 1px solid var(--border-strong); color: #fff;
    font-size: 13px; display: grid; place-items: center; transition: all var(--dur-fast) var(--ease);
  }
  .check.on { background: var(--ok); border-color: var(--ok); }
  .check:active { transform: scale(0.9); }

  .mini {
    width: 26px; height: 26px; border-radius: var(--pill); flex-shrink: 0;
    background: transparent; border: 1px solid transparent; color: var(--faint); font-size: 13px;
    display: grid; place-items: center; transition: all var(--dur-fast) var(--ease);
  }
  .mini:hover { color: var(--text); background: var(--surface-2); }
</style>
