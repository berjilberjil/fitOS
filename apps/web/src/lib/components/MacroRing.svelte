<script lang="ts">
  let { value, goal, label, unit, color = 'var(--red)' }: {
    value: number; goal: number; label: string; unit: string; color?: string;
  } = $props();

  const r = 44;
  const circ = 2 * Math.PI * r;
  const pct = $derived(goal > 0 ? Math.min(value / goal, 1) : 0);
  const dash = $derived(circ * pct);
  const over = $derived(goal > 0 && value > goal);
</script>

<div class="ring">
  <svg viewBox="0 0 110 110" width="112" height="112">
    <circle cx="55" cy="55" r={r} fill="none" stroke="var(--surface-2)" stroke-width="9" />
    <circle
      cx="55" cy="55" r={r} fill="none"
      stroke={over ? 'var(--warn)' : color} stroke-width="9"
      stroke-linecap="round" stroke-dasharray="{dash} {circ}"
      transform="rotate(-90 55 55)" class="prog"
    />
    <text x="55" y="53" text-anchor="middle" fill="var(--text)" font-size="21" font-weight="750" class="num">{value}</text>
    <text x="55" y="70" text-anchor="middle" fill="var(--faint)" font-size="9.5" class="num">/ {goal}</text>
  </svg>
  <span class="lbl">{label} <span class="u">{unit}</span></span>
</div>

<style>
  .ring { display: flex; flex-direction: column; align-items: center; gap: 6px; }
  .prog { transition: stroke-dasharray var(--dur-slow) var(--ease), stroke var(--dur) var(--ease); }
  .lbl { font-size: 12px; font-weight: 650; color: var(--muted); }
  .u { color: var(--faint); font-weight: 500; }
</style>
