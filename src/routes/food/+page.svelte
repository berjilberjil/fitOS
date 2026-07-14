<script lang="ts">
  import { profile, saveProfile, DEFAULT_PROFILE } from '$lib/stores/profile';
  import ProfileForm from '$lib/components/ProfileForm.svelte';
  import BmiCard from '$lib/components/BmiCard.svelte';
  import Modal from '$lib/components/Modal.svelte';
  import SegmentedControl from '$lib/components/SegmentedControl.svelte';
  import TodayView from '$lib/components/TodayView.svelte';
  import PlanView from '$lib/components/PlanView.svelte';
  import FoodsView from '$lib/components/FoodsView.svelte';

  let editing = $state(false);
  let segment = $state('Today');
  const segments = ['Today', 'Plan', 'Foods'];
</script>

{#if !$profile.onboarded}
  <div class="onboard rise">
    <span class="eyebrow">Welcome</span>
    <h1 class="h1 title">Set up LuxiFit</h1>
    <p class="muted lead">A quick profile powers your BMI, calorie and protein targets.</p>
    <div class="card obcard">
      <ProfileForm initial={DEFAULT_PROFILE} onsave={(p) => saveProfile(p)} />
    </div>
  </div>
{:else}
  <header class="pagehead">
    <div>
      <span class="eyebrow">Nutrition</span>
      <h1 class="h1">Food</h1>
    </div>
  </header>

  <div class="bmiwrap"><BmiCard profile={$profile} onedit={() => (editing = true)} /></div>

  <div class="seg"><SegmentedControl options={segments} value={segment} onchange={(v) => (segment = v)} /></div>

  {#key segment}
    <div class="view rise">
      {#if segment === 'Today'}<TodayView />
      {:else if segment === 'Plan'}<PlanView />
      {:else}<FoodsView />{/if}
    </div>
  {/key}

  <Modal open={editing} title="Edit profile" onclose={() => (editing = false)}>
    <ProfileForm initial={$profile} onsave={(p) => { saveProfile(p); editing = false; }} />
  </Modal>
{/if}

<style>
  .onboard { display: flex; flex-direction: column; gap: 6px; }
  .title { margin-top: 4px; }
  .lead { margin: 2px 0 16px; }
  .obcard { padding: 18px; }
  .pagehead { margin-bottom: 14px; }
  .pagehead .eyebrow { display: block; margin-bottom: 3px; }
  .bmiwrap { margin-bottom: 16px; }
  .seg { margin-bottom: 16px; }
</style>
