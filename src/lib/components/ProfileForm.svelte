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

  function submit() {
    onsave({ ...p });
  }
</script>

<div class="form">
  <label>Age<input type="number" min="10" max="100" bind:value={p.age} /></label>
  <label>Sex
    <select bind:value={p.sex}>
      <option value="male">Male</option>
      <option value="female">Female</option>
    </select>
  </label>
  <label>Height (cm)<input type="number" min="100" max="230" bind:value={p.heightCm} /></label>
  <label>Current weight (kg)<input type="number" min="25" max="250" step="0.1" bind:value={p.currentWeightKg} /></label>
  <label>Target weight (kg)<input type="number" min="25" max="250" step="0.1" bind:value={p.targetWeightKg} /></label>
  <label>Activity
    <select bind:value={p.activity}>
      {#each activityOptions as o}<option value={o.v}>{o.l}</option>{/each}
    </select>
  </label>
  <button class="btn-primary" onclick={submit}>Save</button>
</div>

<style>
  .form { display: flex; flex-direction: column; gap: 14px; }
  label { display: flex; flex-direction: column; gap: 6px; font-size: 13px; font-weight: 600; color: var(--muted); }
  input, select {
    background: var(--surface-2); color: var(--text); border: 1px solid #2a2a2e;
    border-radius: 10px; padding: 12px; font-size: 16px;
  }
</style>
