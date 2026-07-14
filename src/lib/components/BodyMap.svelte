<script lang="ts">
  // Stylised male figure. Each muscle region is clickable and lights up when active.
  let { view, active, onselect }: {
    view: 'front' | 'back';
    active: string | null;
    onselect: (region: string) => void;
  } = $props();

  const cls = (region: string) => (active === region ? 'region on' : 'region');
</script>

<svg viewBox="0 0 200 470" class="body" role="group" aria-label="{view} body muscle map">
  <!-- shared base silhouette -->
  <g class="base">
    <circle cx="100" cy="30" r="18" />
    <path d="M90 46 h20 v9 q-10 6 -20 0 Z" />
    <path d="M66 78 Q56 84 55 100 L60 165 Q66 196 84 208 Q100 220 116 208 Q134 196 140 165 L145 100 Q144 84 134 78 Z" />
    <path d="M60 84 Q42 96 40 140 Q38 180 44 214 L54 214 Q52 178 56 140 Q60 110 70 96 Z" />
    <path d="M140 84 Q158 96 160 140 Q162 180 156 214 L146 214 Q148 178 144 140 Q140 110 130 96 Z" />
    <path d="M84 208 Q78 262 82 330 Q84 382 88 432 L99 432 L100 214 Z" />
    <path d="M116 208 Q122 262 118 330 Q116 382 112 432 L101 432 L100 214 Z" />
    <circle cx="44" cy="222" r="7" /><circle cx="156" cy="222" r="7" />
    <ellipse cx="89" cy="442" rx="9" ry="6" /><ellipse cx="111" cy="442" rx="9" ry="6" />
  </g>

  {#if view === 'front'}
    <g class={cls('shoulders')} onclick={() => onselect('shoulders')} role="button" tabindex="0" aria-label="Shoulders">
      <ellipse cx="60" cy="90" rx="14" ry="15" /><ellipse cx="140" cy="90" rx="14" ry="15" />
    </g>
    <g class={cls('chest')} onclick={() => onselect('chest')} role="button" tabindex="0" aria-label="Chest">
      <path d="M97 90 Q76 88 74 106 Q76 124 97 122 Z" /><path d="M103 90 Q124 88 126 106 Q124 124 103 122 Z" />
    </g>
    <g class={cls('core')} onclick={() => onselect('core')} role="button" tabindex="0" aria-label="Core">
      <path d="M84 128 L116 128 L113 190 Q100 202 87 190 Z" />
      <line x1="100" y1="130" x2="100" y2="196" /><line x1="86" y1="150" x2="114" y2="150" /><line x1="86" y1="170" x2="114" y2="170" />
    </g>
    <g class={cls('biceps')} onclick={() => onselect('biceps')} role="button" tabindex="0" aria-label="Biceps">
      <ellipse cx="52" cy="126" rx="10" ry="24" /><ellipse cx="148" cy="126" rx="10" ry="24" />
    </g>
    <g class={cls('forearms')} onclick={() => onselect('forearms')} role="button" tabindex="0" aria-label="Forearms">
      <ellipse cx="46" cy="180" rx="8" ry="26" /><ellipse cx="154" cy="180" rx="8" ry="26" />
    </g>
    <g class={cls('quads')} onclick={() => onselect('quads')} role="button" tabindex="0" aria-label="Quads">
      <path d="M85 220 Q74 262 84 322 L98 322 L99 222 Z" /><path d="M115 220 Q126 262 116 322 L102 322 L101 222 Z" />
    </g>
  {:else}
    <g class={cls('back')} onclick={() => onselect('back')} role="button" tabindex="0" aria-label="Back">
      <path d="M78 74 L122 74 L110 98 L100 106 L90 98 Z" />
      <path d="M80 104 Q70 144 88 182 L100 172 L100 106 Z" /><path d="M120 104 Q130 144 112 182 L100 172 L100 106 Z" />
    </g>
    <g class={cls('triceps')} onclick={() => onselect('triceps')} role="button" tabindex="0" aria-label="Triceps">
      <ellipse cx="52" cy="126" rx="10" ry="24" /><ellipse cx="148" cy="126" rx="10" ry="24" />
    </g>
    <g class={cls('glutes')} onclick={() => onselect('glutes')} role="button" tabindex="0" aria-label="Glutes">
      <path d="M82 204 Q80 234 100 238 Q120 234 118 204 Q100 214 82 204 Z" />
    </g>
    <g class={cls('hamstrings')} onclick={() => onselect('hamstrings')} role="button" tabindex="0" aria-label="Hamstrings">
      <path d="M85 244 Q76 286 85 330 L98 330 L99 244 Z" /><path d="M115 244 Q124 286 115 330 L102 330 L101 244 Z" />
    </g>
    <g class={cls('calves')} onclick={() => onselect('calves')} role="button" tabindex="0" aria-label="Calves">
      <ellipse cx="89" cy="372" rx="9" ry="28" /><ellipse cx="111" cy="372" rx="9" ry="28" />
    </g>
  {/if}
</svg>

<style>
  .body { width: 100%; max-width: 260px; height: auto; display: block; margin: 0 auto; overflow: visible; }
  .base { fill: var(--surface-2); stroke: var(--border); stroke-width: 1.4; }
  .region { fill: var(--elevated); stroke: var(--border-strong); stroke-width: 1.2; cursor: pointer; outline: none; }
  .region line { stroke: var(--bg); stroke-width: 1.2; }
  .region:hover { fill: var(--red-soft); stroke: var(--red-line); }
  .region.on { fill: var(--red); stroke: #ff6b76; animation: pulse 1.4s var(--ease) infinite; }
  .region.on line { stroke: rgba(0, 0, 0, 0.25); }
  .region { transition: fill var(--dur) var(--ease), stroke var(--dur) var(--ease); }
  @keyframes pulse {
    0%, 100% { filter: drop-shadow(0 0 0 rgba(245, 49, 63, 0)); }
    50% { filter: drop-shadow(0 0 7px rgba(245, 49, 63, 0.6)); }
  }
  @media (prefers-reduced-motion: reduce) { .region.on { animation: none; } }
</style>
