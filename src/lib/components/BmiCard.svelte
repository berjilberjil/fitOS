<script lang="ts">
  import type { Profile } from '$lib/types';
  import { bmi, bmiStatus, targetBmi, bmr, tdee, proteinGoal } from '$lib/utils/nutrition';

  let { profile, onedit }: { profile: Profile; onedit: () => void } = $props();

  const value = $derived(bmi(profile.currentWeightKg, profile.heightCm));
  const status = $derived(bmiStatus(value));
  const target = $derived(targetBmi(profile.targetWeightKg, profile.heightCm));
  const calGoal = $derived(
    tdee(bmr(profile.sex, profile.currentWeightKg, profile.heightCm, profile.age), profile.activity)
  );
  const protGoal = $derived(proteinGoal(profile.currentWeightKg));
</script>

<div class="card bmi">
  <div class="line">
    <div>
      <div class="big">{value}</div>
      <div class="muted">BMI</div>
    </div>
    <span class="pill {status}">{status}</span>
    <button class="edit" onclick={onedit} aria-label="Edit profile">⚙️</button>
  </div>
  <div class="stats">
    <div><span class="muted">Target BMI</span><b>{target}</b></div>
    <div><span class="muted">Calorie goal</span><b>{calGoal}</b></div>
    <div><span class="muted">Protein goal</span><b>{protGoal} g</b></div>
  </div>
</div>

<style>
  .bmi { padding: 16px; display: flex; flex-direction: column; gap: 14px; }
  .line { display: flex; align-items: center; gap: 14px; }
  .big { font-size: 34px; font-weight: 800; line-height: 1; }
  .pill { padding: 4px 10px; border-radius: 999px; font-size: 12px; font-weight: 700; text-transform: capitalize; }
  .pill.normal { background: #14351f; color: #4ade80; }
  .pill.underweight { background: #10263b; color: #60a5fa; }
  .pill.overweight { background: #3a2a10; color: #fbbf24; }
  .pill.obese { background: var(--red-dim); color: #fca5a5; }
  .edit { margin-left: auto; background: none; border: none; font-size: 18px; }
  .stats { display: grid; grid-template-columns: repeat(3, 1fr); gap: 8px; }
  .stats div { display: flex; flex-direction: column; gap: 2px; font-size: 13px; }
  .stats .muted { font-size: 11px; }
</style>
