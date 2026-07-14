<script lang="ts">
  import type { Profile } from '$lib/types';

  let { initial, onsave }: { initial: Profile; onsave: (p: Profile) => void } = $props();

  let p = $state<Profile>({ ...initial });
  const activityOptions = [
    { v: 1.2, l: 'Sedentary' },
    { v: 1.375, l: 'Light' },
    { v: 1.55, l: 'Moderate' },
    { v: 1.725, l: 'Very active' }
  ];
</script>

<div class="form">
  <div class="two">
    <label>Age<input class="input" type="number" min="10" max="100" bind:value={p.age} /></label>
    <label>Sex
      <select class="select" bind:value={p.sex}>
        <option value="male">Male</option>
        <option value="female">Female</option>
      </select>
    </label>
  </div>
  <label>Height (cm)<input class="input" type="number" min="100" max="230" bind:value={p.heightCm} /></label>
  <div class="two">
    <label>Current weight (kg)<input class="input" type="number" min="25" max="250" step="0.1" bind:value={p.currentWeightKg} /></label>
    <label>Target weight (kg)<input class="input" type="number" min="25" max="250" step="0.1" bind:value={p.targetWeightKg} /></label>
  </div>
  <label>Activity
    <select class="select" bind:value={p.activity}>
      {#each activityOptions as o}<option value={o.v}>{o.l}</option>{/each}
    </select>
  </label>
  <button class="btn btn-primary save" onclick={() => onsave({ ...p })}>Save</button>
</div>

<style>
  .form { display: flex; flex-direction: column; gap: 14px; }
  .two { display: grid; grid-template-columns: 1fr 1fr; gap: 12px; }
  label { display: flex; flex-direction: column; gap: 7px; font-size: 12.5px; font-weight: 650; color: var(--muted); }
  .save { margin-top: 4px; }
</style>
