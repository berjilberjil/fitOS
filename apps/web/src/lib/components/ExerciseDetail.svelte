<script lang="ts">
  import type { Exercise } from '$lib/types';
  import { exGif, exStill } from '$lib/data/exercise-media';
  import { categoryDef } from '$lib/data/workouts';
  import Icon from './Icon.svelte';
  import { workoutCatIcon, EXERCISE_FALLBACK } from '$lib/icons';

  let { exercise, onadd }: { exercise: Exercise; onadd?: () => void } = $props();

  const gif = $derived(exGif(exercise.id));
  const still = $derived(exStill(exercise.id));
  const media = $derived(gif ?? still);
  const cat = $derived(categoryDef(exercise.category));
</script>

<div class="detail">
  <div class="stage" class:empty={!media}>
    {#if media}
      <img class="demo" src={media} alt="{exercise.name} demonstration" />
      {#if gif}<span class="live">▶ live</span>{/if}
    {:else}
      <span class="bigemoji"><Icon icon={EXERCISE_FALLBACK} size={54} /></span>
      <span class="nomedia">Demo image not available</span>
    {/if}
  </div>

  <div class="facts">
    <span class="fact"><span class="fl">Category</span><Icon icon={workoutCatIcon(exercise.category)} size={15} /> {cat.label}</span>
    <span class="fact"><span class="fl">Equipment</span>{exercise.equipment}</span>
    <span class="fact"><span class="fl">Targets</span>{exercise.primary}</span>
  </div>

  {#if onadd}
    <button class="btn btn-primary add" onclick={onadd}>＋ Add to today</button>
  {/if}
</div>

<style>
  .detail { display: flex; flex-direction: column; gap: 14px; }
  /* Source GIF is 180×180 — cap the stage so it isn't upscaled into blur. */
  .stage {
    position: relative; width: min(100%, 300px); margin: 0 auto; aspect-ratio: 1 / 1;
    background: #f4f4f5; border-radius: var(--radius-md); overflow: hidden;
    display: grid; place-items: center;
  }
  .stage.empty { background: var(--surface-2); gap: 8px; }
  .demo { width: 100%; height: 100%; object-fit: contain; display: block; }
  .live {
    position: absolute; top: 10px; right: 10px; background: var(--red); color: #fff;
    font-size: 10px; font-weight: 800; letter-spacing: 0.04em; padding: 3px 8px; border-radius: var(--pill);
  }
  .bigemoji { font-size: 60px; }
  .nomedia { font-size: 12px; color: var(--muted); }

  .facts { display: flex; flex-direction: column; gap: 8px; }
  .fact { display: flex; align-items: center; gap: 10px; font-size: 13.5px; font-weight: 600; }
  .fl { font-size: 10px; font-weight: 700; letter-spacing: 0.06em; text-transform: uppercase; color: var(--faint); width: 74px; flex-shrink: 0; }
  .add { width: 100%; }
</style>
