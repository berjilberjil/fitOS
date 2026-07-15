<script lang="ts">
  import type { MuscleGroup } from '$lib/data/anatomy';
  import Icon from './Icon.svelte';
  import { muscleIcon } from '$lib/icons';

  let { group }: { group: MuscleGroup } = $props();
</script>

<div class="detail">
  <header class="dh">
    <span class="ic"><Icon icon={muscleIcon(group.id)} size={26} /></span>
    <div>
      <h2 class="h2">{group.name}</h2>
      <span class="count">{group.muscles.length} muscles</span>
    </div>
  </header>
  <p class="blurb muted">{group.blurb}</p>

  {#key group.id}
    <div class="muscles stagger">
      {#each group.muscles as m, i}
        <div class="muscle card card-sm">
          <div class="top"><span class="idx num">{i + 1}</span><span class="mn">{m.name}</span></div>
          <p class="what">{m.what}</p>
          <div class="train"><span class="tl">Train</span> {m.train}</div>
        </div>
      {/each}
    </div>
  {/key}
</div>

<style>
  .detail { display: flex; flex-direction: column; gap: 12px; }
  .dh { display: flex; align-items: center; gap: 12px; }
  .ic { font-size: 30px; }
  .count { font-size: 11px; font-weight: 700; letter-spacing: 0.06em; text-transform: uppercase; color: var(--faint); }
  .blurb { font-size: 13px; line-height: 1.5; }
  .muscles { display: flex; flex-direction: column; gap: 8px; }
  .muscle { padding: 12px 13px; }
  .top { display: flex; align-items: center; gap: 9px; margin-bottom: 5px; }
  .idx { width: 20px; height: 20px; border-radius: var(--pill); background: var(--red-soft); color: var(--red-bright); font-size: 11px; font-weight: 800; display: grid; place-items: center; flex-shrink: 0; }
  .mn { font-weight: 700; font-size: 14px; }
  .what { font-size: 12.5px; color: var(--muted); line-height: 1.5; margin: 0 0 7px; }
  .train { font-size: 12px; color: var(--text); }
  .tl { font-size: 10px; font-weight: 700; letter-spacing: 0.06em; text-transform: uppercase; color: var(--faint); margin-right: 5px; }
</style>
