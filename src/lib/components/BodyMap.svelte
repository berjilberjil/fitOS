<script lang="ts">
  import {
    bodyFront, bodyBack, frontOutline, backOutline, FRONT_VIEWBOX, BACK_VIEWBOX
  } from '$lib/data/body-paths';

  let { view, activeSlugs, interactiveSlugs, onselect }: {
    view: 'front' | 'back';
    activeSlugs: string[];
    interactiveSlugs: string[];
    onselect: (slug: string) => void;
  } = $props();

  const muscles = $derived(view === 'front' ? bodyFront : bodyBack);
  const outline = $derived(view === 'front' ? frontOutline : backOutline);
  const viewBox = $derived(view === 'front' ? FRONT_VIEWBOX : BACK_VIEWBOX);

  const isActive = (slug: string) => activeSlugs.includes(slug);
  const isClickable = (slug: string) => interactiveSlugs.includes(slug);
</script>

<svg {viewBox} class="body" role="group" aria-label="{view} body muscle map">
  {#each muscles as m (m.slug)}
    {#each m.paths as d, i (i)}
      <path
        {d}
        class="muscle"
        class:on={isActive(m.slug)}
        class:clickable={isClickable(m.slug)}
        onclick={() => isClickable(m.slug) && onselect(m.slug)}
        role={isClickable(m.slug) ? 'button' : undefined}
        tabindex={isClickable(m.slug) ? 0 : undefined}
        aria-label={m.slug}
      />
    {/each}
  {/each}
  <path class="outline" d={outline} />
</svg>

<style>
  .body { width: 100%; max-width: 240px; height: auto; display: block; margin: 0 auto; overflow: visible; }
  .outline { fill: none; stroke: var(--border-strong); stroke-width: 2; vector-effect: non-scaling-stroke; pointer-events: none; }
  .muscle {
    fill: var(--surface-2); stroke: var(--bg); stroke-width: 1.2;
    transition: fill var(--dur) var(--ease);
  }
  .muscle.clickable { fill: var(--elevated); cursor: pointer; }
  .muscle.clickable:hover { fill: var(--red-soft); }
  .muscle.on { fill: var(--red); animation: glow 1.5s var(--ease) infinite; }
  @keyframes glow {
    0%, 100% { filter: drop-shadow(0 0 0 rgba(245, 49, 63, 0)); }
    50% { filter: drop-shadow(0 0 6px rgba(245, 49, 63, 0.7)); }
  }
  @media (prefers-reduced-motion: reduce) { .muscle.on { animation: none; } }
</style>
