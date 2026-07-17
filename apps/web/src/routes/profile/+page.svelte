<script lang="ts">
  import { profile, saveProfile } from '$lib/stores/profile';
  import { currentUser, logout } from '$lib/stores/auth';
  import { theme, setTheme, type ThemeMode } from '$lib/stores/theme';
  import {
    reminders,
    setMaster,
    setReminderEnabled,
    setReminderTime,
    resetReminders,
    requestBrowserPermission
  } from '$lib/stores/reminders';
  import ProfileForm from '$lib/components/ProfileForm.svelte';
  import Icon from '$lib/components/Icon.svelte';

  const modes: { id: ThemeMode; label: string; icon: string }[] = [
    { id: 'system', label: 'System', icon: 'lucide:monitor' },
    { id: 'light', label: 'Light', icon: 'lucide:sun' },
    { id: 'dark', label: 'Dark', icon: 'lucide:moon' }
  ];

  let permMsg = $state('');

  async function enableBrowserNotifs() {
    const p = await requestBrowserPermission();
    if (p === 'granted') permMsg = 'Browser notifications allowed. Full daily schedule works best in the iOS app.';
    else if (p === 'unsupported') permMsg = 'This browser can’t schedule local reminders — use the fitOS iPhone app for daily alarms.';
    else permMsg = 'Permission denied. Enable notifications in browser settings, or use the iOS app.';
  }
</script>

<header class="pagehead">
  <span class="eyebrow">Account</span>
  <h1 class="h1">Profile</h1>
  {#if $currentUser}
    <p class="who muted">Signed in as <b>{$currentUser.username}</b></p>
  {/if}
</header>

<section class="card blk rise">
  <span class="eyebrow">Appearance</span>
  <div class="themes" role="group" aria-label="Theme">
    {#each modes as m}
      <button
        type="button"
        class="tbtn"
        class:on={$theme === m.id}
        onclick={() => setTheme(m.id)}
      >
        <Icon icon={m.icon} size={18} />
        <span>{m.label}</span>
      </button>
    {/each}
  </div>
</section>

<section class="card blk rise">
  <span class="eyebrow">Reminders</span>
  <p class="hint muted">
    Customize daily meal, gym, log & rest times. <b>Reliable daily notifications run on the iOS app</b>
    (Profile → Reminders). Times here are saved on this device.
  </p>
  <label class="master">
    <input type="checkbox" checked={$reminders.masterEnabled} onchange={(e) => setMaster(e.currentTarget.checked)} />
    <span>Daily reminders on</span>
  </label>
  {#if $reminders.masterEnabled}
    <div class="remlist">
      {#each $reminders.items as r (r.id)}
        <div class="rem" class:off={!r.enabled}>
          <label class="renable">
            <input
              type="checkbox"
              checked={r.enabled}
              onchange={(e) => setReminderEnabled(r.id, e.currentTarget.checked)}
            />
            <span class="rtitle">{r.title}</span>
          </label>
          <input
            class="input rtime"
            type="time"
            value={r.time}
            disabled={!r.enabled}
            onchange={(e) => setReminderTime(r.id, e.currentTarget.value)}
          />
        </div>
      {/each}
    </div>
    <div class="racts">
      <button type="button" class="btn btn-outline" onclick={resetReminders}>Reset defaults</button>
      <button type="button" class="btn btn-primary" onclick={enableBrowserNotifs}>Allow browser alerts</button>
    </div>
    {#if permMsg}<p class="perm muted">{permMsg}</p>{/if}
    <p class="defaults muted">Defaults: Log 05:00 · Breakfast 08:00 · Lunch 13:00 · Gym 16:30 · Dinner 20:00 · Rest 21:30</p>
  {/if}
</section>

<section class="card blk rise">
  <span class="eyebrow">Body & goals</span>
  <p class="hint muted">Used for BMI, calories and protein targets. Weight is clamped to 30–250 kg.</p>
  <ProfileForm initial={$profile} onsave={(p) => saveProfile(p)} />
</section>

<section class="card blk rise dangerzone">
  <button type="button" class="btn btn-danger full" onclick={logout}>Log out</button>
</section>

<style>
  .pagehead { margin-bottom: 16px; }
  .pagehead .eyebrow { display: block; margin-bottom: 3px; }
  .who { margin: 6px 0 0; font-size: 13px; }
  .who b { color: var(--text); font-weight: 700; }

  .blk { padding: 16px 17px; margin-bottom: 14px; }
  .blk .eyebrow { display: block; margin-bottom: 12px; }
  .hint { font-size: 12.5px; margin: -4px 0 14px; line-height: 1.45; }

  .themes {
    display: grid; grid-template-columns: repeat(3, 1fr); gap: 8px;
  }
  .tbtn {
    display: flex; flex-direction: column; align-items: center; gap: 6px;
    padding: 12px 8px; border-radius: var(--radius-md);
    border: 1px solid var(--border); background: var(--surface-2);
    color: var(--muted); font-size: 12px; font-weight: 650;
    transition: all var(--dur-fast) var(--ease);
  }
  .tbtn:hover { color: var(--text); border-color: var(--border-strong); }
  .tbtn.on {
    color: var(--red); border-color: var(--red-line);
    background: var(--red-soft);
  }

  .dangerzone { padding: 14px 17px; }
  .full { width: 100%; }

  .master {
    display: flex; align-items: center; gap: 10px;
    font-weight: 650; font-size: 14px; margin-bottom: 12px;
  }
  .master input { width: 18px; height: 18px; accent-color: var(--red); }
  .remlist { display: flex; flex-direction: column; gap: 8px; }
  .rem {
    display: flex; align-items: center; justify-content: space-between; gap: 12px;
    padding: 10px 12px; border-radius: var(--radius-md);
    background: var(--surface-2); border: 1px solid var(--border);
  }
  .rem.off { opacity: 0.55; }
  .renable { display: flex; align-items: center; gap: 10px; flex: 1; min-width: 0; }
  .renable input { width: 16px; height: 16px; accent-color: var(--red); flex-shrink: 0; }
  .rtitle { font-weight: 650; font-size: 13.5px; }
  .rtime { width: auto; max-width: 120px; padding: 8px 10px; font-size: 14px; }
  .racts { display: flex; flex-wrap: wrap; gap: 8px; margin-top: 12px; }
  .perm { font-size: 12px; margin: 10px 0 0; line-height: 1.4; }
  .defaults { font-size: 11px; margin: 10px 0 0; line-height: 1.4; }
</style>
