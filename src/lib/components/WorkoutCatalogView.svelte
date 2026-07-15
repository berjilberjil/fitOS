<script lang="ts">
  import { exercises } from '$lib/stores/exercises';
  import type { Exercise, WorkoutCategory } from '$lib/types';
  import { WORKOUT_CATEGORIES } from '$lib/data/workouts';
  import { workoutPlan } from '$lib/stores/workout-plan';
  import { addExerciseToDay } from '$lib/stores/workout-log';
  import { todayKey } from '$lib/stores/log';
  import { exThumb, hasDemo } from '$lib/data/exercise-media';
  import Thumb from './Thumb.svelte';
  import Modal from './Modal.svelte';
  import ExerciseDetail from './ExerciseDetail.svelte';
  import Icon from './Icon.svelte';
  import { workoutCatIcon, EXERCISE_FALLBACK } from '$lib/icons';

  let filter = $state<WorkoutCategory | 'all'>('all');
  let query = $state('');
  let toast = $state('');
  let toastT: ReturnType<typeof setTimeout>;
  let demo = $state<Exercise | null>(null);

  const shown = $derived(WORKOUT_CATEGORIES.filter((c) => filter === 'all' || c.key === filter));
  function forCat(key: WorkoutCategory) {
    return $exercises.filter(
      (e) => e.category === key && e.name.toLowerCase().includes(query.toLowerCase())
    );
  }

  function addToToday(e: Exercise) {
    addExerciseToDay(todayKey(), e.id, $workoutPlan);
    toast = `${e.name} added to today`;
    clearTimeout(toastT);
    toastT = setTimeout(() => (toast = ''), 1600);
  }
</script>

<input class="input" placeholder="Search exercises…" bind:value={query} />

<div class="chips">
  <button class="chip" class:on={filter === 'all'} onclick={() => (filter = 'all')}>All</button>
  {#each WORKOUT_CATEGORIES as c}
    <button class="chip catchip" class:on={filter === c.key} onclick={() => (filter = c.key)}>
      <Icon icon={workoutCatIcon(c.key)} size={14} /> {c.label}
    </button>
  {/each}
</div>

<div class="cats">
  {#each shown as c (c.key)}
    {@const list = forCat(c.key)}
    {#if list.length}
      <section class="cat">
        <header class="chead">
          <span class="cic"><Icon icon={workoutCatIcon(c.key)} size={18} /></span>
          <span class="cname">{c.label}</span>
          <span class="ccount num muted">{list.length}</span>
        </header>
        <div class="grid stagger">
          {#each list as e (e.id)}
            <div class="tile card">
              <button class="cover" onclick={() => (demo = e)} aria-label="See {e.name} demo">
                <Thumb src={exThumb(e.id)} fallback={EXERCISE_FALLBACK} size={112} radius={12} alt={e.name} />
                {#if hasDemo(e.id)}<span class="play">▶</span>{/if}
              </button>
              <div class="tmeta">
                <span class="tnm">{e.name}</span>
                <span class="tsub muted">{e.primary}</span>
              </div>
              <button class="addbtn" onclick={() => addToToday(e)} aria-label="Add {e.name} to today">＋</button>
            </div>
          {/each}
        </div>
      </section>
    {/if}
  {/each}
</div>

<Modal open={!!demo} title={demo?.name ?? ''} onclose={() => (demo = null)}>
  {#if demo}
    <ExerciseDetail exercise={demo} onadd={() => { addToToday(demo!); demo = null; }} />
  {/if}
</Modal>

{#if toast}<div class="toast rise">{toast} ✓</div>{/if}

<style>
  .chips { display: flex; gap: 6px; overflow-x: auto; margin: 12px 0 18px; padding-bottom: 2px; }
  .catchip { display: inline-flex; align-items: center; gap: 5px; }
  .cats { display: flex; flex-direction: column; gap: 20px; }
  .cat { display: flex; flex-direction: column; }
  .chead { display: flex; align-items: center; gap: 9px; margin-bottom: 11px; }
  .cic { font-size: 18px; }
  .cname { font-weight: 750; font-size: 15px; letter-spacing: -0.01em; }
  .ccount { margin-left: auto; font-size: 12px; }

  .grid { display: grid; grid-template-columns: 1fr 1fr; gap: 10px; }
  @media (min-width: 560px) { .grid { grid-template-columns: repeat(3, 1fr); } }
  @media (min-width: 860px) { .grid { grid-template-columns: repeat(4, 1fr); } }

  .tile { position: relative; padding: 8px; display: flex; flex-direction: column; gap: 8px; overflow: hidden; }
  .cover {
    position: relative; width: 100%; aspect-ratio: 1 / 1; border-radius: 12px; overflow: hidden;
    background: var(--surface-2); border: none; padding: 0; display: grid; place-items: center;
    transition: transform var(--dur-fast) var(--ease);
  }
  .cover :global(img.thumb) { width: 100% !important; height: 100% !important; border-radius: 12px; border: none; }
  .cover :global(.emoji) { width: 100% !important; height: 100% !important; font-size: 46px !important; }
  .cover:hover { transform: scale(1.02); }
  .cover:active { transform: scale(0.98); }
  .play {
    position: absolute; bottom: 7px; right: 7px; width: 24px; height: 24px; border-radius: 50%;
    background: rgba(0, 0, 0, 0.6); color: #fff; font-size: 10px; display: grid; place-items: center;
    padding-left: 2px; backdrop-filter: blur(2px);
  }
  .tmeta { display: flex; flex-direction: column; gap: 1px; padding: 0 2px 2px; min-width: 0; }
  .tnm { font-weight: 650; font-size: 13px; line-height: 1.25; }
  .tsub { font-size: 11px; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
  .addbtn {
    position: absolute; top: 12px; right: 12px; width: 28px; height: 28px; border-radius: var(--pill);
    background: var(--red); color: #fff; border: none; font-size: 17px; line-height: 1;
    display: grid; place-items: center; box-shadow: 0 2px 8px rgba(0, 0, 0, 0.4);
    transition: transform var(--dur-fast) var(--ease);
  }
  .addbtn:hover { background: var(--red-hover); }
  .addbtn:active { transform: scale(0.88); }

  .toast {
    position: fixed; left: 50%; transform: translateX(-50%);
    bottom: calc(var(--nav-h) + 16px + env(safe-area-inset-bottom)); z-index: 70;
    background: var(--elevated); border: 1px solid var(--border-strong); color: var(--text);
    padding: 10px 18px; border-radius: var(--pill); font-size: 13px; font-weight: 650;
    box-shadow: 0 8px 24px rgba(0, 0, 0, 0.5);
  }
  @media (min-width: 860px) { .toast { bottom: 28px; } }
</style>
