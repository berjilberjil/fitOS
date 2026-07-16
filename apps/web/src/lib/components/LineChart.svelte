<script lang="ts">
  let { data, unit = '', color = 'var(--red)' }: {
    data: { x: string; y: number }[];
    unit?: string;
    color?: string;
  } = $props();

  const W = 300;
  const H = 110;
  const P = 8;

  const ys = $derived(data.map((d) => d.y));
  const min = $derived(ys.length ? Math.min(...ys) : 0);
  const max = $derived(ys.length ? Math.max(...ys) : 0);
  const range = $derived(max - min || 1);

  const sx = (i: number) => (data.length <= 1 ? W / 2 : P + (i / (data.length - 1)) * (W - 2 * P));
  const sy = (v: number) => H - P - ((v - min) / range) * (H - 2 * P);

  const line = $derived(data.map((d, i) => `${i === 0 ? 'M' : 'L'}${sx(i)},${sy(d.y)}`).join(' '));
  const area = $derived(
    data.length ? `${line} L${sx(data.length - 1)},${H} L${sx(0)},${H} Z` : ''
  );
</script>

{#if data.length >= 2}
  <div class="chartwrap">
    <svg viewBox="0 0 {W} {H}" class="chart" preserveAspectRatio="none">
      <path class="area" d={area} style="fill:{color}" />
      <path class="line" d={line} style="stroke:{color}" />
    </svg>
    <span class="hi num">{max}{unit}</span>
    <span class="lo num">{min}{unit}</span>
  </div>
{:else}
  <p class="empty muted">Log your weight a few times to see the trend.</p>
{/if}

<style>
  .chartwrap { position: relative; }
  .chart { width: 100%; height: 110px; display: block; overflow: visible; }
  .area { opacity: 0.14; }
  .line { fill: none; stroke-width: 2.5; vector-effect: non-scaling-stroke; stroke-linejoin: round; stroke-linecap: round; }
  .hi, .lo { position: absolute; right: 2px; font-size: 10px; font-weight: 700; color: var(--faint); }
  .hi { top: 0; }
  .lo { bottom: 0; }
  .empty { font-size: 13px; padding: 16px 0; text-align: center; }
</style>
