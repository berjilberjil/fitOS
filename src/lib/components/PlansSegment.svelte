<script lang="ts">
  import { plans, addPlan, updatePlan, deletePlan } from '$lib/stores/plans';
  import { foods, findFood } from '$lib/stores/foods';
  import { applyPlanToDay, todayKey } from '$lib/stores/log';
  import { scaleMacros, sumMacros } from '$lib/utils/nutrition';
  import type { DietPlan, Macros } from '$lib/types';
  import Modal from './Modal.svelte';
  import Fab from './Fab.svelte';
  import PlanForm from './PlanForm.svelte';

  let creating = $state(false);
  let editing = $state<DietPlan | null>(null);
  let applied = $state<string | null>(null);

  function planTotal(plan: DietPlan) {
    const macros = plan.items
      .map((it) => {
        const f = findFood($foods, it.foodId);
        return f ? scaleMacros(f.perServing, it.quantity) : null;
      })
      .filter((m): m is Macros => m !== null);
    return sumMacros(macros);
  }

  function apply(plan: DietPlan) {
    applyPlanToDay(todayKey(), plan, $foods);
    applied = plan.name;
    setTimeout(() => (applied = null), 1800);
  }
</script>

{#if applied}<div class="toast">Added “{applied}” to today ✓</div>{/if}

<div class="list">
  {#each $plans as plan (plan.id)}
    {@const t = planTotal(plan)}
    <div class="pcard card">
      <div class="ph">
        <div class="pn">{plan.name}</div>
        <button class="edit" onclick={() => (editing = plan)} aria-label="Edit plan">✎</button>
      </div>
      <div class="muted meta">{plan.items.length} items · {t.calories} kcal · P {t.protein}</div>
      <button class="btn-primary apply" onclick={() => apply(plan)}>Apply to today</button>
    </div>
  {/each}
  {#if $plans.length === 0}<p class="muted">No plans yet. Tap + to build a repeatable diet.</p>{/if}
</div>

<Fab onclick={() => (creating = true)} />

<Modal open={creating} title="New plan" onclose={() => (creating = false)}>
  <PlanForm onsave={(name, items) => { addPlan(name, items); creating = false; }} />
</Modal>

<Modal open={!!editing} title="Edit plan" onclose={() => (editing = null)}>
  {#if editing}
    <PlanForm
      initial={editing}
      onsave={(name, items) => { updatePlan({ ...editing!, name, items }); editing = null; }}
      ondelete={() => { deletePlan(editing!.id); editing = null; }}
    />
  {/if}
</Modal>

<style>
  .list { display: flex; flex-direction: column; gap: 10px; padding-bottom: 90px; }
  .pcard { padding: 14px; display: flex; flex-direction: column; gap: 8px; }
  .ph { display: flex; align-items: center; justify-content: space-between; }
  .pn { font-weight: 700; font-size: 16px; }
  .meta { font-size: 12px; }
  .edit { background: var(--surface-2); border: 1px solid #2a2a2e; color: var(--muted); border-radius: 8px; width: 32px; height: 32px; }
  .apply { margin-top: 4px; }
  .toast { position: fixed; left: 50%; transform: translateX(-50%); bottom: calc(var(--nav-h) + 80px); background: var(--surface-2); border: 1px solid var(--red); color: #fff; padding: 10px 16px; border-radius: 999px; z-index: 60; font-size: 13px; }
</style>
