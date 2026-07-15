<script lang="ts">
  import type { WeekPlan, MealKey } from '$lib/types';
  import { foods, findFood } from '$lib/stores/foods';
  import { addFoodToMeal, weekdayOf } from '$lib/stores/log';
  import { MEALS, MEAL_KEYS } from '$lib/data/meals';
  import { isSpeechSupported, createRecognizer, type Recognizer } from '$lib/voice/speech';
  import { parseFoodLog, type ParsedFoodLog } from '$lib/voice/parseFoodLog';
  import { foodImage } from '$lib/data/food-images';
  import Modal from './Modal.svelte';
  import SegmentedControl from './SegmentedControl.svelte';
  import Thumb from './Thumb.svelte';
  import Icon from './Icon.svelte';
  import { MIC_ICON } from '$lib/icons';

  let { date, plan }: { date: string; plan: WeekPlan } = $props();

  type Phase = 'listening' | 'parsing' | 'review' | 'error';
  let open = $state(false);
  let phase = $state<Phase>('listening');
  let transcript = $state('');
  let errorMsg = $state('');
  let parsed = $state<ParsedFoodLog | null>(null);
  let reviewMeal = $state<MealKey>('breakfast');
  let rec: Recognizer | null = null;

  const supported = isSpeechSupported();

  const mealLabel = (k: MealKey) => MEALS.find((m) => m.key === k)?.label ?? k;
  const mealKeyOf = (label: string): MealKey => MEALS.find((m) => m.label === label)?.key ?? 'snacks';

  function plannedIds(): string[] {
    const day = plan[weekdayOf(date)];
    if (!day) return [];
    return MEAL_KEYS.flatMap((k) => (day[k] ?? []).map((it) => it.foodId));
  }
  function guessMeal(): MealKey {
    const h = new Date().getHours();
    if (h < 11) return 'breakfast';
    if (h < 16) return 'lunch';
    if (h < 21) return 'dinner';
    return 'snacks';
  }

  function launch() {
    if (!supported) {
      errorMsg = 'Voice needs Chrome or Safari on this device.';
      phase = 'error';
      open = true;
      return;
    }
    startListening();
  }

  function startListening() {
    transcript = '';
    errorMsg = '';
    phase = 'listening';
    open = true;
    rec = createRecognizer({
      onpartial: (t) => (transcript = t),
      onfinal: (t) => {
        transcript = t;
        runParse(t);
      },
      onerror: (code) => {
        errorMsg = code === 'no-speech' ? "Didn't catch that — tap and try again." : `Mic error: ${code}`;
        phase = 'error';
      }
    });
    rec?.start();
  }

  function stopListening() {
    rec?.stop();
    if (transcript.trim() && phase === 'listening') runParse(transcript.trim());
  }

  async function runParse(text: string) {
    if (phase === 'parsing') return;
    phase = 'parsing';
    try {
      const result = await parseFoodLog({ transcript: text, foods: $foods, plannedFoodIds: plannedIds() });
      parsed = result;
      reviewMeal = result.meal ?? guessMeal();
      phase = 'review';
    } catch (e) {
      errorMsg = (e as Error)?.message ?? 'Could not understand that.';
      phase = 'error';
    }
  }

  function applyLog() {
    if (!parsed) return;
    for (const it of parsed.items) {
      if (it.foodId && findFood($foods, it.foodId) && it.quantity > 0) {
        addFoodToMeal(date, reviewMeal, it.foodId, Math.round(it.quantity * 100) / 100, plan);
      }
    }
    close();
  }

  function close() {
    rec?.stop();
    open = false;
    parsed = null;
    transcript = '';
  }

  const rows = $derived(
    (parsed?.items ?? []).map((it) => ({ it, food: it.foodId ? findFood($foods, it.foodId) : undefined }))
  );
  const matched = $derived(rows.filter((r) => !!r.food));
  const unmatched = $derived(rows.filter((r) => !r.food));
  const title = $derived(
    phase === 'listening' ? 'Listening…' : phase === 'parsing' ? 'Reading your meal…' : phase === 'review' ? 'Log this?' : 'Voice log'
  );
</script>

<button class="mic" onclick={launch} aria-label="Log food by voice">
  <Icon icon={MIC_ICON} size={15} /> Speak to log
</button>

<Modal {open} {title} onclose={close}>
  {#if phase === 'listening'}
    <div class="pane listen">
      <div class="pulse"><span class="ring"></span><Icon icon={MIC_ICON} size={30} /></div>
      <p class="heard">{transcript || 'Say what you ate… e.g. "3 chapati and 100ml milk for breakfast"'}</p>
      <button class="btn btn-primary grow" onclick={stopListening}>Done</button>
    </div>
  {:else if phase === 'parsing'}
    <div class="pane center">
      <div class="spinner"></div>
      <p class="muted quote">"{transcript}"</p>
    </div>
  {:else if phase === 'review' && parsed}
    <div class="pane">
      <div class="mealsel">
        <span class="lbl muted">Add to</span>
        <SegmentedControl
          options={MEALS.map((m) => m.label)}
          value={mealLabel(reviewMeal)}
          onchange={(v) => (reviewMeal = mealKeyOf(v))}
        />
      </div>

      {#if matched.length}
        <div class="items">
          {#each matched as row, i (i)}
            <div class="item">
              <Thumb src={foodImage(row.it.foodId ?? '')} size={34} radius={9} alt={row.food?.name ?? ''} />
              <div class="imeta">
                <span class="inm">{row.food?.name ?? row.it.foodName}</span>
                <span class="isub muted">{row.food?.servingLabel}</span>
              </div>
              <input class="qty num" type="number" min="0" step="0.25" bind:value={row.it.quantity} />
              <span class="sv muted">×</span>
            </div>
          {/each}
        </div>
      {:else}
        <p class="muted none">Nothing matched your foods. Try again or add these in the Foods tab.</p>
      {/if}

      {#if unmatched.length}
        <p class="unmatched">Not in your foods: {unmatched.map((r) => r.it.foodName).join(', ')} — add them in Foods.</p>
      {/if}

      <div class="actions">
        <button class="btn btn-ghost" onclick={startListening}>↻ Redo</button>
        <button class="btn btn-primary grow" onclick={applyLog} disabled={!matched.length}>
          Add {matched.length} to {mealLabel(reviewMeal)}
        </button>
      </div>
    </div>
  {:else}
    <div class="pane">
      <p class="err">{errorMsg}</p>
      <div class="actions">
        <button class="btn btn-outline" onclick={close}>Close</button>
        <button class="btn btn-primary grow" onclick={startListening}>Try again</button>
      </div>
    </div>
  {/if}
</Modal>

<style>
  .mic {
    display: inline-flex; align-items: center; gap: 8px;
    background: var(--red); color: #fff; border: none;
    border-radius: var(--pill); padding: 10px 18px; font-size: 13.5px; font-weight: 700;
    box-shadow: 0 4px 16px rgba(238, 46, 36, 0.3);
    transition: transform var(--dur-fast) var(--ease), background var(--dur-fast) var(--ease);
  }
  .mic:hover { background: var(--red-hover); }
  .mic:active { transform: scale(0.96); }
  .dot { width: 7px; height: 7px; border-radius: 50%; background: #fff; opacity: 0.9; }

  .pane { display: flex; flex-direction: column; gap: 14px; }
  .actions { display: flex; gap: 10px; }
  .grow { flex: 1; }

  .listen { align-items: center; text-align: center; }
  .pulse { position: relative; font-size: 34px; width: 84px; height: 84px; display: grid; place-items: center; margin: 6px 0; }
  .ring { position: absolute; inset: 0; border-radius: 50%; border: 2px solid var(--red); animation: ripple 1.4s var(--ease) infinite; }
  @keyframes ripple { 0% { transform: scale(0.7); opacity: 0.8; } 100% { transform: scale(1.25); opacity: 0; } }
  .heard { font-size: 15px; font-weight: 600; line-height: 1.45; min-height: 44px; }

  .center { align-items: center; text-align: center; gap: 18px; padding: 12px 0; }
  .quote { font-size: 13px; font-style: italic; }
  .spinner { width: 34px; height: 34px; border-radius: 50%; border: 3px solid var(--surface-2); border-top-color: var(--red); animation: spin 0.8s linear infinite; }
  @keyframes spin { to { transform: rotate(360deg); } }

  .mealsel { display: flex; flex-direction: column; gap: 7px; }
  .lbl { font-size: 11px; font-weight: 700; letter-spacing: 0.06em; text-transform: uppercase; }
  .items { display: flex; flex-direction: column; gap: 6px; }
  .item { display: flex; align-items: center; gap: 10px; padding: 8px 4px; border-bottom: 1px solid var(--border); }
  .item:last-child { border-bottom: none; }
  .imeta { flex: 1; min-width: 0; display: flex; flex-direction: column; gap: 1px; }
  .inm { font-weight: 650; font-size: 14px; }
  .isub { font-size: 11.5px; }
  .qty { width: 62px; text-align: center; background: var(--surface-2); color: var(--text); border: 1px solid var(--border); border-radius: var(--radius-sm); padding: 7px 6px; font-size: 14px; font-weight: 700; }
  .sv { font-size: 12px; }
  .none { font-size: 13px; padding: 8px 0; }
  .unmatched { font-size: 12px; color: var(--red-bright); background: var(--red-soft); padding: 8px 11px; border-radius: var(--radius-sm); }
  .err { font-size: 14px; color: var(--text); }
</style>
