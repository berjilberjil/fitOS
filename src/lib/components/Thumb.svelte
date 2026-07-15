<script lang="ts">
  // Image thumbnail with an SVG-icon fallback (no emojis). Falls back on a
  // missing url OR a runtime load error.
  import Icon from './Icon.svelte';
  import { FOOD_FALLBACK } from '$lib/icons';

  let {
    src = undefined,
    emoji = undefined,
    fallback = FOOD_FALLBACK,
    size = 30,
    radius = 9,
    alt = ''
  }: {
    src?: string;
    emoji?: string; // legacy, ignored — kept so existing callers don't break
    fallback?: string;
    size?: number;
    radius?: number;
    alt?: string;
  } = $props();

  void emoji;

  let failed = $state(false);
  $effect(() => {
    void src;
    failed = false;
  });
</script>

{#if src && !failed}
  <img
    class="thumb"
    {src}
    {alt}
    loading="lazy"
    style="width:{size}px;height:{size}px;border-radius:{radius}px"
    onerror={() => (failed = true)}
  />
{:else}
  <span class="fallback" style="width:{size}px;height:{size}px;border-radius:{radius}px">
    <Icon icon={fallback} size={Math.round(size * 0.5)} />
  </span>
{/if}

<style>
  .thumb { object-fit: cover; display: block; flex-shrink: 0; background: var(--surface-2); border: 1px solid var(--border); }
  .fallback { display: grid; place-items: center; flex-shrink: 0; background: var(--surface-2); border: 1px solid var(--border); color: var(--faint); }
</style>
