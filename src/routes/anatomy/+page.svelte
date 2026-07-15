<script lang="ts">
  import { muscleGroups } from '$lib/data/anatomy';
  import BodyMap from '$lib/components/BodyMap.svelte';
  import MuscleDetail from '$lib/components/MuscleDetail.svelte';
  import SegmentedControl from '$lib/components/SegmentedControl.svelte';

  let view = $state<'front' | 'back'>('front');
  let selectedId = $state(muscleGroups[0].id);

  const selected = $derived(muscleGroups.find((g) => g.id === selectedId)!);
  const activeSlugs = $derived(selected.view === view ? selected.slugs : []);
  const interactiveSlugs = $derived(
    muscleGroups.filter((g) => g.view === view).flatMap((g) => g.slugs)
  );

  function pickSlug(slug: string) {
    const g = muscleGroups.find((x) => x.view === view && x.slugs.includes(slug));
    if (g) selectedId = g.id;
  }
  function pickGroup(id: string) {
    const g = muscleGroups.find((x) => x.id === id)!;
    view = g.view;
    selectedId = id;
  }
</script>

<header class="pagehead">
  <span class="eyebrow">Know your body</span>
  <h1 class="h1">Anatomy</h1>
  <p class="muted sub">Tap a muscle to see the split every gym-goer should know — head to toe.</p>
</header>

<div class="toggle">
  <SegmentedControl
    options={['Front', 'Back']}
    value={view === 'front' ? 'Front' : 'Back'}
    onchange={(v) => (view = v === 'Front' ? 'front' : 'back')}
  />
</div>

<div class="groups">
  {#each muscleGroups as g}
    <button class="gchip" class:on={g.id === selectedId} onclick={() => pickGroup(g.id)}>
      <span class="gi">{g.icon}</span><span class="gn">{g.name}</span>
    </button>
  {/each}
</div>

<div class="explore">
  <div class="bodycard card">
    <BodyMap {view} {activeSlugs} {interactiveSlugs} onselect={pickSlug} />
    <div class="viewhint muted">{view === 'front' ? 'Front view' : 'Back view'} · tap a muscle</div>
    <div class="credit">Body model: react-native-body-highlighter · MIT</div>
  </div>
  <div class="detailwrap">
    <MuscleDetail group={selected} />
  </div>
</div>

<style>
  .pagehead { margin-bottom: 14px; }
  .pagehead .eyebrow { display: block; margin-bottom: 3px; }
  .sub { font-size: 13px; margin: 4px 0 0; }
  .toggle { max-width: 260px; margin: 0 0 14px; }
  .groups { display: flex; flex-wrap: wrap; gap: 6px; margin-bottom: 16px; }
  .gchip {
    display: inline-flex; align-items: center; gap: 6px;
    background: var(--surface-2); border: 1px solid var(--border); color: var(--muted);
    border-radius: var(--pill); padding: 7px 12px; font-size: 12.5px; font-weight: 650;
    transition: all var(--dur-fast) var(--ease);
  }
  .gchip:hover { color: var(--text); border-color: var(--border-strong); }
  .gchip.on { background: var(--red); color: #fff; border-color: var(--red); }
  .gi { font-size: 14px; }

  .explore { display: grid; grid-template-columns: 1fr; gap: 16px; }
  .bodycard { padding: 18px; display: flex; flex-direction: column; gap: 8px; align-items: center; }
  .viewhint { font-size: 11.5px; font-weight: 600; }
  .credit { font-size: 9.5px; color: var(--faint); letter-spacing: 0.02em; }
  @media (min-width: 720px) {
    .explore { grid-template-columns: 300px 1fr; align-items: start; }
    .bodycard { position: sticky; top: 24px; }
  }
</style>
