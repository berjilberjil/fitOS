import adapterNode from '@sveltejs/adapter-node';
import adapterNetlify from '@sveltejs/adapter-netlify';
import { vitePreprocess } from '@sveltejs/vite-plugin-svelte';

// Netlify sets NETLIFY=true during its build → use the Netlify adapter there.
// Locally (and for the Tauri iOS dev server) we keep adapter-node running,
// so the native app keeps working during the transition.
const onNetlify = !!process.env.NETLIFY;

/** @type {import('@sveltejs/kit').Config} */
const config = {
  preprocess: vitePreprocess(),
  kit: {
    adapter: onNetlify ? adapterNetlify() : adapterNode()
  }
};

export default config;
