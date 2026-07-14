<script lang="ts">
  let { onclick, label = '+' }: { onclick: () => void; label?: string } = $props();
</script>

<button class="fab" {onclick} aria-label="Add">{label}</button>

<style>
  .fab {
    position: fixed; right: max(16px, calc((100vw - var(--maxw)) / 2 + 16px));
    bottom: calc(var(--nav-h) + 16px + env(safe-area-inset-bottom));
    width: 56px; height: 56px; border-radius: 50%; border: none;
    background: var(--red); color: #fff; font-size: 28px; line-height: 1;
    box-shadow: 0 6px 18px rgba(224,30,43,0.4); z-index: 40;
  }
</style>
