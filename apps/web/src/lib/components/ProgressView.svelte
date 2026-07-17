<script lang="ts">
  import { profile } from '$lib/stores/profile';
  import { weightLog, logWeight, weightSeries } from '$lib/stores/weight-log';
  import {
    bmi, bmiStatus, bodyFat, sixPackBodyFat, weightAtBodyFat, weeksToLose,
    bmr, tdee, proteinGoal, round1
  } from '$lib/utils/nutrition';
  import LineChart from './LineChart.svelte';

  const STEP = 0.25; // 250 g per tap

  const series = $derived(weightSeries($weightLog));
  const currentKg = $derived(series.length ? series[series.length - 1].kg : $profile.currentWeightKg);
  const todayKey = $derived(new Date().toISOString().slice(0, 10));
  const todayKg = $derived($weightLog[todayKey] ?? currentKg);
  const bmiVal = $derived(bmi(currentKg, $profile.heightCm));
  const status = $derived(bmiStatus(bmiVal));
  const bf = $derived(bodyFat(bmiVal, $profile.age, $profile.sex));
  const targetBF = $derived(sixPackBodyFat($profile.sex));
  const goalWeight = $derived(weightAtBodyFat(currentKg, bf, targetBF));
  const kgToLose = $derived(Math.max(round1(currentKg - goalWeight), 0));
  const weeks = $derived(weeksToLose(kgToLose));
  const tdeeVal = $derived(tdee(bmr($profile.sex, currentKg, $profile.heightCm, $profile.age), $profile.activity));
  const prot = $derived(proteinGoal(currentKg));
  const journey = $derived(Math.min(Math.max((25 - bf) / (25 - targetBF), 0), 1) * 100);
  const chartData = $derived(series.map((p) => ({ x: p.date, y: p.kg })));

  const statusLabel = $derived(
    status === 'underweight' ? 'Underweight' : status === 'normal' ? 'Normal' : status === 'overweight' ? 'Overweight' : 'Obese'
  );

  const eta = $derived.by(() => {
    if (kgToLose <= 0) return null;
    const d = new Date();
    d.setDate(d.getDate() + weeks * 7);
    return d.toLocaleDateString('en-GB', { month: 'short', year: 'numeric' });
  });

  const plan = $derived.by(() => {
    if (bmiVal < 18.5)
      return { tag: 'Lean bulk', kcal: tdeeVal + 300, tip: 'You’re underweight — eat a small surplus, hit protein, and add weight to the bar each week.' };
    if (kgToLose <= 0)
      return { tag: 'Reveal & hold', kcal: tdeeVal - 200, tip: 'You’re already in abs-visible range — hold a light deficit and keep training to sharpen up.' };
    if (bmiVal >= 25 || bf > targetBF + 6)
      return { tag: 'Cut', kcal: tdeeVal - 500, tip: 'Run a ~500 kcal deficit, keep protein high to hold muscle, and lift 3–4×/week.' };
    return { tag: 'Recomp', kcal: tdeeVal, tip: 'Eat around maintenance and push progressive overload — build muscle while the fat slowly drops.' };
  });

  function bumpWeight(delta: number) {
    const next = Math.round((todayKg + delta) * 100) / 100;
    // Match BODY_WEIGHT_MIN/MAX (30–250 kg) — blocks runaway 494 kg bugs.
    if (!(next >= 30 && next <= 250)) return;
    logWeight(next);
    profile.update((p) => ({ ...p, currentWeightKg: next }));
  }
</script>

<div class="wrap stagger">
  <!-- Weight + trend -->
  <section class="card blk">
    <div class="wtop">
      <div>
        <span class="eyebrow">Today's weight</span>
        <div class="big num">{todayKg}<span class="u">kg</span></div>
      </div>
      <div class="wstep">
        <button class="stepbtn" type="button" aria-label="Decrease 0.25 kg" onclick={() => bumpWeight(-STEP)}>−</button>
        <span class="stephint">±{STEP}</span>
        <button class="stepbtn" type="button" aria-label="Increase 0.25 kg" onclick={() => bumpWeight(STEP)}>+</button>
      </div>
    </div>
    <p class="wnote muted">Tap + / − for 0.25 kg (250 g) steps — no typing.</p>
    <LineChart data={chartData} unit="kg" />
  </section>

  <!-- Body composition -->
  <section class="card blk">
    <span class="eyebrow">Body composition</span>
    <div class="stats">
      <div class="stat">
        <span class="sv num">{bmiVal}</span>
        <span class="sl">BMI</span>
        <span class="badge s-{status}">{statusLabel}</span>
      </div>
      <div class="stat">
        <span class="sv num">{bf}%</span>
        <span class="sl">Body fat (est.)</span>
      </div>
      <div class="stat">
        <span class="sv num">{Math.round(currentKg * (1 - bf / 100))}<span class="u">kg</span></span>
        <span class="sl">Lean mass</span>
      </div>
    </div>
  </section>

  <!-- Six-pack goal -->
  <section class="card blk">
    <div class="ghead">
      <span class="eyebrow">Path to a six-pack</span>
      <span class="tgt muted num">target {targetBF}% BF</span>
    </div>
    {#if kgToLose > 0}
      <p class="gline">
        Abs typically show around <b>{targetBF}% body fat</b>. From <b>{bf}%</b>, that’s about
        <b class="red">{kgToLose} kg</b> to lose → roughly <b>{weeks} weeks</b>{#if eta}, around <b>{eta}</b>{/if}
        at a steady 0.5 kg/week.
      </p>
      <div class="journeywrap">
        <span class="jbar" style="width:{journey}%"></span>
      </div>
      <div class="jrow muted"><span>now {bf}%</span><span>goal {targetBF}%</span></div>
      <div class="gstats">
        <div><span class="gv num">{goalWeight}<span class="u">kg</span></span><span class="gl">goal weight</span></div>
        <div><span class="gv num">{kgToLose}<span class="u">kg</span></span><span class="gl">to lose</span></div>
        <div><span class="gv num">{weeks}</span><span class="gl">weeks</span></div>
      </div>
    {:else}
      <p class="gline">You’re already at or below <b>{targetBF}% body fat</b> — abs range. Hold a light deficit and keep training to stay sharp.</p>
    {/if}
  </section>

  <!-- Suggestion -->
  <section class="card blk sugg">
    <div class="sughead">
      <span class="eyebrow">What to do now</span>
      <span class="plan">{plan.tag}</span>
    </div>
    <p class="tip">{plan.tip}</p>
    <div class="targets">
      <div><span class="tv num">{plan.kcal}</span><span class="tl">kcal / day</span></div>
      <div><span class="tv num">{prot}<span class="u">g</span></span><span class="tl">protein / day</span></div>
    </div>
  </section>
</div>

<style>
  .wrap { display: flex; flex-direction: column; gap: 14px; }
  .blk { padding: 16px 17px; }
  .eyebrow { display: block; }
  .u { font-size: 0.5em; font-weight: 600; color: var(--muted); margin-left: 2px; }

  .wtop { display: flex; align-items: flex-end; justify-content: space-between; gap: 12px; margin-bottom: 8px; }
  .big { font-size: 38px; font-weight: 750; letter-spacing: -0.03em; line-height: 1; margin-top: 4px; }
  .wstep { display: flex; align-items: center; gap: 10px; }
  .stepbtn {
    width: 44px; height: 44px; border-radius: 12px;
    border: 1px solid var(--border); background: var(--surface-2);
    color: var(--text); font-size: 22px; font-weight: 700; line-height: 1;
    display: grid; place-items: center;
    transition: background 150ms ease, transform 120ms ease;
  }
  .stepbtn:active { transform: scale(0.94); background: var(--red-soft); color: var(--red); }
  .stephint { font-size: 12px; font-weight: 700; color: var(--faint); min-width: 36px; text-align: center; }
  .wnote { font-size: 11.5px; margin: 0 0 12px; }

  .stats, .gstats, .targets { display: flex; justify-content: space-between; gap: 10px; }
  .stats { margin-top: 12px; }
  .stat { display: flex; flex-direction: column; gap: 3px; align-items: flex-start; }
  .sv { font-size: 22px; font-weight: 750; letter-spacing: -0.02em; }
  .sl { font-size: 10.5px; font-weight: 700; letter-spacing: 0.05em; text-transform: uppercase; color: var(--faint); }
  .badge { margin-top: 2px; }
  .s-normal { background: var(--ok-soft); color: var(--ok); }
  .s-underweight { background: var(--info-soft); color: var(--info); }
  .s-overweight { background: var(--warn-soft); color: var(--warn); }
  .s-obese { background: var(--red-soft); color: var(--red-bright); }

  .ghead, .sughead { display: flex; align-items: baseline; justify-content: space-between; gap: 8px; margin-bottom: 10px; }
  .tgt { font-size: 11px; }
  .gline { font-size: 13.5px; line-height: 1.55; margin: 0 0 14px; }
  .gline b { font-weight: 750; }
  .gline .red { color: var(--red); }
  .journeywrap { height: 8px; background: var(--surface-2); border-radius: 5px; overflow: hidden; }
  .jbar { display: block; height: 100%; background: linear-gradient(90deg, var(--warn), var(--red)); border-radius: 5px; transition: width var(--dur-slow) var(--ease); }
  .jrow { display: flex; justify-content: space-between; font-size: 10.5px; font-weight: 700; margin: 5px 0 14px; }
  .gstats > div, .targets > div { display: flex; flex-direction: column; gap: 2px; }
  .gv, .tv { font-size: 19px; font-weight: 750; letter-spacing: -0.02em; }
  .gl, .tl { font-size: 10px; font-weight: 700; letter-spacing: 0.05em; text-transform: uppercase; color: var(--faint); }

  .sugg { background: linear-gradient(180deg, var(--red-soft), var(--surface)); border-color: var(--red-line); }
  .plan { font-size: 13px; font-weight: 800; color: var(--red); }
  .tip { font-size: 13.5px; line-height: 1.55; margin: 0 0 14px; }
  .targets { justify-content: flex-start; gap: 28px; }
</style>
