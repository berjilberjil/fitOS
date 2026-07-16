<script lang="ts">
  import type { Exercise } from '$lib/types';
  import { exercises, findExercise } from '$lib/stores/exercises';
  import {
    workoutPlan, addPlanExercise, setPlanSets, setPlanReps,
    swapPlanExercise, removePlanExercise, setRestDay, copyWorkoutDay
  } from '$lib/stores/workout-plan';
  import { WEEKDAYS, WEEKDAYS_LONG } from '$lib/data/meals';
  import Modal from './Modal.svelte';
  import ExercisePicker from './ExercisePicker.svelte';
  import ExerciseDetail from './ExerciseDetail.svelte';
  import WorkoutRow from './WorkoutRow.svelte';
  import Icon from './Icon.svelte';
  import { REST_ICON } from '$lib/icons';

  let weekday = $state(new Date().getDay());
  const day = $derived($workoutPlan[weekday] ?? { rest: false, items: [] });

  interface Row { ex: Exercise; index: number; sets: number; reps: number; }
  const rows = $derived(
    day.items
      .map((it, index): Row | null => {
        const ex = findExercise($exercises, it.exerciseId);
        return ex ? { ex, index, sets: it.sets, reps: it.reps } : null;
      })
      .filter((r): r is Row => r !== null)
  );

  // add / swap
  let picker = $state<{ index: number | null } | null>(null);
  function handlePick(exerciseId: string) {
    if (!picker) return;
    if (picker.index === null) addPlanExercise(weekday, exerciseId);
    else swapPlanExercise(weekday, picker.index, exerciseId);
    picker = null;
  }

  let demo = $state<Exercise | null>(null);

  // copy this day to selected weekdays
  let targets = $state<number[]>([]);
  let copied = $state(false);
  function toggleTarget(d: number) {
    if (d === weekday) return;
    targets = targets.includes(d) ? targets.filter((x) => x !== d) : [...targets, d];
  }
  function selectAll() {
    const all = [0, 1, 2, 3, 4, 5, 6].filter((d) => d !== weekday);
    targets = targets.length === all.length ? [] : all;
  }
  function applyCopy() {
    if (!targets.length) return;
    copyWorkoutDay(weekday, targets);
    copied = true;
    targets = [];
    setTimeout(() => (copied = false), 1600);
  }
</script>

<div class="intro">
  <p class="muted note">Build a routine per weekday. Each day auto-fills from it — on Today you just log the weight. Set rest days too.</p>
</div>

<div class="wdbar">
  {#each WEEKDAYS as w, i}
    <button class="wd" class:on={i === weekday} class:rest={$workoutPlan[i]?.rest} onclick={() => (weekday = i)}>{w}</button>
  {/each}
</div>

<div class="dayhead">
  <span class="dname">{WEEKDAYS_LONG[weekday]}</span>
  <label class="restsw">
    <input type="checkbox" checked={day.rest} onchange={(e) => setRestDay(weekday, e.currentTarget.checked)} />
    <span>Rest day</span>
  </label>
</div>

{#if day.rest}
  <div class="restnote card"><Icon icon={REST_ICON} size={15} /> Rest day — no training scheduled. Uncheck above to add exercises.</div>
{:else}
  <div class="session card">
    {#if rows.length}
      <div class="rows">
        {#each rows as r (r.index)}
          <WorkoutRow
            exercise={r.ex}
            mode="plan"
            sets={r.sets}
            reps={r.reps}
            onsets={(v) => setPlanSets(weekday, r.index, v)}
            onreps={(v) => setPlanReps(weekday, r.index, v)}
            onremove={() => removePlanExercise(weekday, r.index)}
            onshowdemo={() => (demo = r.ex)}
          />
        {/each}
      </div>
    {:else}
      <p class="empty muted">No exercises yet. Add the ones you'll train on {WEEKDAYS_LONG[weekday]}.</p>
    {/if}
    <button class="add" onclick={() => (picker = { index: null })}>＋ Add exercise</button>
  </div>

  <div class="copy card">
    <div class="copyhead">
      <span class="ctitle">Copy {WEEKDAYS_LONG[weekday]} to…</span>
      <button class="selall" onclick={selectAll}>{targets.length ? 'Clear' : 'All days'}</button>
    </div>
    <div class="tgts">
      {#each WEEKDAYS as w, i}
        <button
          class="tgt"
          class:on={targets.includes(i)}
          class:self={i === weekday}
          disabled={i === weekday}
          onclick={() => toggleTarget(i)}
        >{w}</button>
      {/each}
    </div>
    <button class="btn btn-outline apply" disabled={!targets.length && !copied} onclick={applyCopy}>
      {copied ? 'Copied ✓' : targets.length ? `Copy to ${targets.length} day${targets.length > 1 ? 's' : ''}` : 'Pick days to copy to'}
    </button>
  </div>
{/if}

<Modal open={!!picker} title={picker?.index === null ? 'Add exercise' : 'Swap exercise'} onclose={() => (picker = null)}>
  <ExercisePicker onpick={handlePick} />
</Modal>

<Modal open={!!demo} title={demo?.name ?? ''} onclose={() => (demo = null)}>
  {#if demo}<ExerciseDetail exercise={demo} />{/if}
</Modal>

<style>
  .intro { margin-bottom: 12px; }
  .note { font-size: 13px; line-height: 1.5; }
  .wdbar { display: flex; gap: 5px; overflow-x: auto; padding-bottom: 12px; }
  .wd {
    flex: 1; min-width: 44px; padding: 9px 0; border-radius: var(--radius-sm);
    background: var(--surface-2); border: 1px solid var(--border); color: var(--muted);
    font-weight: 700; font-size: 12px; transition: all var(--dur-fast) var(--ease); position: relative;
  }
  .wd:hover { color: var(--text); }
  .wd.on { background: var(--red); color: #fff; border-color: var(--red); }
  .wd.rest:not(.on) { color: var(--faint); }
  .wd.rest::after { content: ''; position: absolute; top: 5px; right: 6px; width: 4px; height: 4px; border-radius: 50%; background: var(--faint); }
  .wd.on.rest::after { background: #fff; }

  .dayhead { display: flex; align-items: center; justify-content: space-between; margin-bottom: 12px; }
  .dname { font-weight: 750; font-size: 17px; letter-spacing: -0.02em; }
  .restsw { display: inline-flex; align-items: center; gap: 7px; font-size: 12.5px; font-weight: 650; color: var(--muted); cursor: pointer; }
  .restsw input { width: 16px; height: 16px; accent-color: var(--red); }

  .restnote { padding: 18px; font-size: 13px; color: var(--muted); text-align: center; }
  .session { padding: 14px 15px; }
  .rows { margin: 2px 0 4px; }
  .empty { font-size: 13px; padding: 10px 4px; line-height: 1.5; }
  .add {
    width: 100%; margin-top: 8px; padding: 9px; border-radius: var(--radius-sm);
    background: transparent; border: 1px dashed var(--border-strong); color: var(--muted);
    font-weight: 600; font-size: 13px; transition: all var(--dur-fast) var(--ease);
  }
  .add:hover { color: var(--text); border-color: var(--red-line); background: var(--red-soft); }

  .copy { margin-top: 14px; padding: 14px 15px; }
  .copyhead { display: flex; align-items: center; justify-content: space-between; margin-bottom: 10px; }
  .ctitle { font-weight: 700; font-size: 13.5px; }
  .selall { font-size: 12px; font-weight: 650; color: var(--muted); background: none; border: none; }
  .selall:hover { color: var(--text); }
  .tgts { display: flex; gap: 5px; margin-bottom: 12px; }
  .tgt {
    flex: 1; min-width: 40px; padding: 8px 0; border-radius: var(--radius-sm);
    background: var(--surface-2); border: 1px solid var(--border); color: var(--muted);
    font-weight: 700; font-size: 11.5px; transition: all var(--dur-fast) var(--ease);
  }
  .tgt.on { background: var(--red); color: #fff; border-color: var(--red); }
  .tgt.self { opacity: 0.35; cursor: default; }
  .apply { width: 100%; }
  .apply:disabled { opacity: 0.5; cursor: default; }
</style>
