<script lang="ts">
  import { profile } from '$lib/stores/profile';
  import ProgressView from '$lib/components/ProgressView.svelte';
  import Icon from '$lib/components/Icon.svelte';
  import { PROGRESS_ICON } from '$lib/icons';
</script>

<header class="pagehead">
  <span class="eyebrow">Track</span>
  <h1 class="h1">Progress</h1>
</header>

{#if $profile.onboarded}
  <ProgressView />
{:else}
  <div class="placeholder rise">
    <div class="glyph"><Icon icon={PROGRESS_ICON} size={44} /></div>
    <h2 class="h2">Set up your profile first</h2>
    <p class="muted">Open the <b>Profile</b> tab and enter your age, height and weight — then Progress lights up with your BMI, body-fat and six-pack timeline.</p>
  </div>
{/if}

<style>
  .pagehead { margin-bottom: 14px; }
  .pagehead .eyebrow { display: block; margin-bottom: 3px; }
  .placeholder .glyph { font-size: 44px; }
  .placeholder p { max-width: 320px; font-size: 13.5px; line-height: 1.5; }
  .placeholder b { color: var(--text); }
</style>
