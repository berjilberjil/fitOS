<script lang="ts">
  import type { Exercise } from '$lib/types';
  import { exercises, findExercise } from '$lib/stores/exercises';
  import { workoutPlan } from '$lib/stores/workout-plan';
  import { dateKey, weekdayOf } from '$lib/stores/log';
  import {
    workoutLog, getOrSeedWorkoutDay, lastWeightFor,
    setWeight, toggleDone, swapLogExercise, addExerciseToDay, removeFromDay, setDayRest
  } from '$lib/stores/workout-log';
  import { WEEKDAYS_LONG } from '$lib/data/meals';
  import Modal from './Modal.svelte';
  import ExercisePicker from './ExercisePicker.svelte';
  import ExerciseDetail from './ExerciseDetail.svelte';
  import WorkoutRow from './WorkoutRow.svelte';
  import Icon from './Icon.svelte';
  import { REST_ICON } from '$lib/icons';

  let offset = $state(0);
  function dateForOffset(o: number): string {
    const d = new Date();
    d.setDate(d.getDate() + o);
    return dateKey(d);
  }
  const date = $derived(dateForOffset(offset));
  const day = $derived(getOrSeedWorkoutDay($workoutLog, date, $workoutPlan));
  const relLabel = $derived(offset === 0 ? 'Today' : offset === -1 ? 'Yesterday' : offset === 1 ? 'Tomorrow' : date);

  interface Row { ex: Exercise; index: number; sets: number; reps: number; weightKg: number; done: boolean; lastWeight?: number; }
  const rows = $derived(
    day.items
      .map((it, index): Row | null => {
        const ex = findExercise($exercises, it.exerciseId);
        return ex
          ? { ex, index, sets: it.sets, reps: it.reps, weightKg: it.weightKg, done: it.done, lastWeight: lastWeightFor($workoutLog, it.exerciseId, date) }
          : null;
      })
      .filter((r): r is Row => r !== null)
  );

  const doneCount = $derived(rows.filter((r) => r.done).length);
  const volume = $derived(
    Math.round(rows.reduce((s, r) => s + (r.ex.weighted ? r.sets * r.reps * r.weightKg : 0), 0))
  );

  // add / swap
  let picker = $state<{ index: number | null } | null>(null);
  function handlePick(exerciseId: string) {
    if (!picker) return;
    if (picker.index === null) addExerciseToDay(date, exerciseId, $workoutPlan);
    else swapLogExercise(date, picker.index, exerciseId, $workoutPlan);
    picker = null;
  }

  let demo = $state<Exercise | null>(null);
</script>

<div class="hero card">
  <div class="datebar">
    <button class="icon-btn" onclick={() => (offset -= 1)} aria-label="Previous day">‹</button>
    <div class="dlabel">
      <span class="rel">{relLabel}</span>
      <span class="wd muted">{WEEKDAYS_LONG[weekdayOf(date)]}</span>
    </div>
    <button class="icon-btn" onclick={() => (offset += 1)} aria-label="Next day">›</button>
  </div>

  {#if !day.rest && rows.length}
    <div class="stats">
      <div class="stat"><span class="sv num">{doneCount}/{rows.length}</span><span class="sl">Done</span></div>
      <div class="stat"><span class="sv num">{rows.length}</span><span class="sl">Exercises</span></div>
      <div class="stat"><span class="sv num">{volume.toLocaleString()}</span><span class="sl">Volume kg</span></div>
    </div>
  {/if}
</div>

{#if day.rest}
  <div class="rest card">
    <div class="rglyph"><Icon icon={REST_ICON} size={40} /></div>
    <h2 class="h2">Rest day</h2>
    <p class="muted">Recovery is where muscle is built. Eat, sleep, come back stronger.</p>
    <button class="btn btn-outline" onclick={() => setDayRest(date, false, $workoutPlan)}>Train anyway</button>
  </div>
{:else}
  <div class="session card">
    {#if rows.length}
      <div class="rows">
        {#each rows as r (r.index)}
          <WorkoutRow
            exercise={r.ex}
            mode="log"
            sets={r.sets}
            reps={r.reps}
            weightKg={r.weightKg}
            done={r.done}
            lastWeight={r.lastWeight}
            onweight={(v) => setWeight(date, r.index, v, $workoutPlan)}
            ondone={() => toggleDone(date, r.index, $workoutPlan)}
            onswap={() => (picker = { index: r.index })}
            onremove={() => removeFromDay(date, r.index, $workoutPlan)}
            onshowdemo={() => (demo = r.ex)}
          />
        {/each}
      </div>
    {:else}
      <p class="empty muted">No workout planned for {WEEKDAYS_LONG[weekdayOf(date)]}. Add one below, or set a routine in Plan.</p>
    {/if}
    <button class="add" onclick={() => (picker = { index: null })}>＋ Add exercise</button>
  </div>

  <button class="btn btn-ghost restbtn" onclick={() => setDayRest(date, true, $workoutPlan)}>Make this a rest day</button>
{/if}

<Modal open={!!picker} title={picker?.index === null ? 'Add exercise' : 'Swap exercise'} onclose={() => (picker = null)}>
  <ExercisePicker onpick={handlePick} />
</Modal>

<Modal open={!!demo} title={demo?.name ?? ''} onclose={() => (demo = null)}>
  {#if demo}<ExerciseDetail exercise={demo} />{/if}
</Modal>

<style>
  .hero { padding: 16px; margin-bottom: 14px; }
  .datebar { display: flex; align-items: center; justify-content: space-between; }
  .dlabel { text-align: center; display: flex; flex-direction: column; gap: 1px; }
  .rel { font-weight: 750; font-size: 17px; letter-spacing: -0.02em; }
  .wd { font-size: 12px; }
  .stats { display: flex; justify-content: space-around; border-top: 1px solid var(--border); margin-top: 14px; padding-top: 14px; }
  .stat { display: flex; flex-direction: column; align-items: center; gap: 2px; }
  .sv { font-size: 20px; font-weight: 750; letter-spacing: -0.02em; }
  .sl { font-size: 10px; font-weight: 700; letter-spacing: 0.06em; text-transform: uppercase; color: var(--faint); }

  .session { padding: 14px 15px; }
  .rows { margin: 2px 0 4px; }
  .empty { font-size: 13px; padding: 10px 4px; line-height: 1.5; }
  .add {
    width: 100%; margin-top: 8px; padding: 9px; border-radius: var(--radius-sm);
    background: transparent; border: 1px dashed var(--border-strong); color: var(--muted);
    font-weight: 600; font-size: 13px; transition: all var(--dur-fast) var(--ease);
  }
  .add:hover { color: var(--text); border-color: var(--red-line); background: var(--red-soft); }
  .restbtn { width: 100%; margin-top: 12px; }

  .rest { padding: 30px 20px; display: flex; flex-direction: column; align-items: center; gap: 8px; text-align: center; }
  .rglyph { font-size: 42px; }
  .rest .btn { margin-top: 8px; }
</style>
