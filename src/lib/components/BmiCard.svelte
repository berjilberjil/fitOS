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
  const delta = $derived(Math.round((value - target) * 10) / 10);
</script>

<div class="card bmi">
  <div class="line">
    <div class="lead">
      <div class="big num">{value}</div>
      <div class="eyebrow">BMI</div>
    </div>
    <span class="pill {status}">{status}</span>
    <button class="icon-btn" onclick={onedit} aria-label="Edit profile">⚙</button>
  </div>
  <div class="stats">
    <div><span class="k">Target</span><b class="num">{target}</b></div>
    <div><span class="k">To goal</span><b class="num">{delta > 0 ? `−${delta}` : delta < 0 ? `+${-delta}` : '0'}</b></div>
    <div><span class="k">Calories</span><b class="num">{calGoal}</b></div>
    <div><span class="k">Protein</span><b class="num">{protGoal}g</b></div>
  </div>
</div>

<style>
  .bmi { padding: 16px; display: flex; flex-direction: column; gap: 15px; }
  .line { display: flex; align-items: center; gap: 14px; }
  .lead { display: flex; flex-direction: column; gap: 2px; }
  .big { font-size: 36px; font-weight: 800; line-height: 1; letter-spacing: -0.03em; }
  .pill { padding: 5px 12px; border-radius: var(--pill); font-size: 12px; font-weight: 700; text-transform: capitalize; }
  .pill.normal { background: var(--ok-soft); color: var(--ok); }
  .pill.underweight { background: var(--info-soft); color: var(--info); }
  .pill.overweight { background: var(--warn-soft); color: var(--warn); }
  .pill.obese { background: var(--red-soft); color: #ff6b76; }
  .icon-btn { margin-left: auto; }
  .stats { display: grid; grid-template-columns: repeat(4, 1fr); gap: 8px; border-top: 1px solid var(--border); padding-top: 14px; }
  .stats div { display: flex; flex-direction: column; gap: 3px; }
  .stats .k { font-size: 10.5px; font-weight: 700; letter-spacing: 0.06em; text-transform: uppercase; color: var(--faint); }
  .stats b { font-size: 16px; font-weight: 750; }
</style>
