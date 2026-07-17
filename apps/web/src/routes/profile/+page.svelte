<script lang="ts">
  import { profile, saveProfile } from '$lib/stores/profile';
  import { currentUser, logout } from '$lib/stores/auth';
  import { theme, setTheme, type ThemeMode } from '$lib/stores/theme';
  import ProfileForm from '$lib/components/ProfileForm.svelte';
  import Icon from '$lib/components/Icon.svelte';

  const modes: { id: ThemeMode; label: string; icon: string }[] = [
    { id: 'system', label: 'System', icon: 'lucide:monitor' },
    { id: 'light', label: 'Light', icon: 'lucide:sun' },
    { id: 'dark', label: 'Dark', icon: 'lucide:moon' }
  ];
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
</style>
