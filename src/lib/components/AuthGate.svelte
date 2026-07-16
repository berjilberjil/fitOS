<script lang="ts">
  import { login, register } from '$lib/stores/auth';

  let mode = $state<'login' | 'register'>('login');
  let username = $state('');
  let password = $state('');
  let err = $state('');
  let busy = $state(false);

  async function submit() {
    if (busy || !username.trim() || !password) return;
    err = '';
    busy = true;
    const fn = mode === 'login' ? login : register;
    const msg = await fn(username.trim(), password);
    busy = false;
    if (msg) err = msg;
  }
</script>

<div class="authwrap">
  <div class="card authcard rise">
    <div class="brand"><img class="logo" src="/logo.png" alt="" /> <span class="word">fit<span class="fit">OS</span></span></div>
    <h1 class="h1">{mode === 'login' ? 'Welcome back' : 'Create your account'}</h1>
    <p class="muted sub">
      {mode === 'login' ? 'Log in to your food & workout log.' : 'Pick a username — your data syncs to the server.'}
    </p>

    <form onsubmit={(e) => { e.preventDefault(); submit(); }}>
      <input class="input" placeholder="Username" bind:value={username} autocapitalize="none" autocomplete="username" />
      <input
        class="input"
        type="password"
        placeholder="Password"
        bind:value={password}
        autocomplete={mode === 'login' ? 'current-password' : 'new-password'}
      />
      {#if err}<p class="err">{err}</p>{/if}
      <button class="btn btn-primary full" type="submit" disabled={busy || !username.trim() || !password}>
        {busy ? '…' : mode === 'login' ? 'Log in' : 'Sign up'}
      </button>
    </form>

    <button class="switch" onclick={() => { mode = mode === 'login' ? 'register' : 'login'; err = ''; }}>
      {mode === 'login' ? 'New here? Create an account' : 'Have an account? Log in'}
    </button>
  </div>
</div>

<style>
  .authwrap { min-height: 100dvh; display: grid; place-items: center; padding: 22px; }
  .authcard { width: 100%; max-width: 380px; padding: 26px 24px; display: flex; flex-direction: column; gap: 6px; }
  .brand { display: flex; align-items: center; gap: 10px; margin-bottom: 14px; }
  .brand .logo { width: 40px; height: 40px; object-fit: contain; flex-shrink: 0; }
  .brand .word { font-weight: 750; letter-spacing: -0.03em; font-size: 20px; }
  .brand .fit { color: var(--red); }
  .sub { font-size: 13px; margin: 2px 0 18px; }
  form { display: flex; flex-direction: column; gap: 10px; }
  .full { width: 100%; margin-top: 4px; }
  .err { font-size: 12.5px; color: #ff8a99; margin: 0; }
  .switch { background: none; border: none; color: var(--muted); font-size: 12.5px; font-weight: 600; margin-top: 14px; }
  .switch:hover { color: var(--text); }
</style>
