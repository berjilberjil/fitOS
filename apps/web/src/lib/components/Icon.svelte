<script lang="ts">
  import Iconify from '@iconify/svelte';
  // Thin wrapper: crisp SVG icon, inherits currentColor, sized in px.
  let { icon, size = 18 }: { icon: string; size?: number } = $props();
</script>

<Iconify {icon} width={size} height={size} style="display:inline-block;vertical-align:-0.15em;flex-shrink:0" />
