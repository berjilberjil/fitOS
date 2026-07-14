<script lang="ts">
  import { profile, saveProfile, DEFAULT_PROFILE } from '$lib/stores/profile';
  import ProfileForm from '$lib/components/ProfileForm.svelte';
  import BmiCard from '$lib/components/BmiCard.svelte';
  import Modal from '$lib/components/Modal.svelte';
  import SegmentedControl from '$lib/components/SegmentedControl.svelte';
  import TodaySegment from '$lib/components/TodaySegment.svelte';
  import FoodsSegment from '$lib/components/FoodsSegment.svelte';
  import PlansSegment from '$lib/components/PlansSegment.svelte';

  let editing = $state(false);
  let segment = $state('Today');
  const segments = ['Today', 'Foods', 'Plans'];
</script>

{#if !$profile.onboarded}
  <div class="screen">
    <h1 class="h1">Welcome to LuxiFit</h1>
    <p class="muted">Set up your profile to get started.</p>
    <div style="margin-top:16px">
      <ProfileForm initial={DEFAULT_PROFILE} onsave={(p) => saveProfile(p)} />
    </div>
  </div>
{:else}
  <div class="screen">
    <div class="head">
      <h1 class="h1">Food</h1>
    </div>
    <BmiCard profile={$profile} onedit={() => (editing = true)} />
    <div style="margin:14px 0">
      <SegmentedControl options={segments} value={segment} onchange={(v) => (segment = v)} />
    </div>

    {#if segment === 'Today'}<TodaySegment />
    {:else if segment === 'Foods'}<FoodsSegment />
    {:else}<PlansSegment />{/if}
  </div>

  <Modal open={editing} title="Edit profile" onclose={() => (editing = false)}>
    <ProfileForm initial={$profile} onsave={(p) => { saveProfile(p); editing = false; }} />
  </Modal>
{/if}

<style>
  .head { margin-bottom: 12px; }
</style>
