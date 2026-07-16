<script lang="ts">
  // Compact −/value/+ control. Tap + to log more, − for less.
  let { value, step = 1, onchange, suffix = '' }: {
    value: number; step?: number; onchange: (v: number) => void; suffix?: string;
  } = $props();

  const dec = () => onchange(Math.max(Math.round((value - step) * 100) / 100, 0));
  const inc = () => onchange(Math.round((value + step) * 100) / 100);
</script>

<div class="stepper" class:zero={value === 0}>
  <button class="step" onclick={dec} aria-label="Less" disabled={value === 0}>−</button>
  <span class="val num">{value}{suffix}</span>
  <button class="step plus" onclick={inc} aria-label="More">+</button>
</div>

<style>
  .stepper {
    display: inline-flex; align-items: center; gap: 2px;
    background: var(--surface-2); border: 1px solid var(--border);
    border-radius: var(--pill); padding: 3px;
  }
  .step {
    width: 30px; height: 30px; border-radius: var(--pill); border: none;
    background: transparent; color: var(--text); font-size: 19px; line-height: 1;
    display: grid; place-items: center; transition: all var(--dur-fast) var(--ease);
  }
  .step:hover:not(:disabled) { background: var(--elevated); }
  .step:active:not(:disabled) { transform: scale(0.88); }
  .step:disabled { color: var(--faint); cursor: default; }
  .step.plus { background: var(--red); color: #fff; }
  .step.plus:hover { background: var(--red-hover); }
  .val { min-width: 30px; text-align: center; font-size: 14px; font-weight: 700; }
  .zero .val { color: var(--faint); }
</style>
