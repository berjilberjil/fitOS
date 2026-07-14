<script lang="ts">
  let { value, goal, label, unit }: {
    value: number; goal: number; label: string; unit: string;
  } = $props();

  const r = 46;
  const circ = 2 * Math.PI * r;
  const pct = $derived(goal > 0 ? Math.min(value / goal, 1) : 0);
  const dash = $derived(circ * pct);
</script>

<div class="ring">
  <svg viewBox="0 0 110 110" width="120" height="120">
    <circle cx="55" cy="55" r={r} fill="none" stroke="var(--surface-2)" stroke-width="10" />
    <circle
      cx="55" cy="55" r={r} fill="none" stroke="var(--red)" stroke-width="10"
      stroke-linecap="round" stroke-dasharray="{dash} {circ}"
      transform="rotate(-90 55 55)"
    />
    <text x="55" y="52" text-anchor="middle" fill="var(--text)" font-size="20" font-weight="700">{value}</text>
    <text x="55" y="70" text-anchor="middle" fill="var(--muted)" font-size="10">/ {goal} {unit}</text>
  </svg>
  <span class="lbl">{label}</span>
</div>

<style>
  .ring { display: flex; flex-direction: column; align-items: center; gap: 4px; }
  .lbl { font-size: 13px; font-weight: 600; color: var(--muted); }
</style>
