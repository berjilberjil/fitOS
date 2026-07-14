# LuxiFit Food Feature Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship the Food feature of LuxiFit — a mobile-first PWA where a user sets up a profile (BMI/goals), logs predefined Tamil-Nadu foods by quantity to auto-compute macros/calories, edits the food database, and builds repeatable diet plans.

**Architecture:** SvelteKit static SPA. Pure nutrition math in `lib/utils` (unit-tested). Four `localStorage`-backed Svelte stores (`profile`, `foods`, `plans`, `log`). One shell layout with a 4-tab bottom nav; only Food is real. The Food page is a client component with a Today/Foods/Plans segmented control.

**Tech Stack:** SvelteKit 2, Svelte 5 (runes), TypeScript, Vite, Vitest (+ jsdom), `@sveltejs/adapter-static`, built-in SvelteKit service worker.

## Global Constraints

- Theme: canvas `#0B0B0C`, surface `#141416`, text `#F5F5F5`, muted `#9A9A9E`, red accent `#E01E2B`. One red only.
- Mobile-first; app content in a centered column, `max-width: 480px`.
- Bottom nav is exactly 4 tabs: **Food, Progress, Workout, Anatomy**. Only Food is functional; the other three are "Coming soon" placeholders.
- Client-only: every route runs with `ssr = false`. Never access `localStorage` at module top level without a `typeof localStorage !== 'undefined'` guard.
- Calorie-from-macros rule (carbs is TOTAL carb, fiber included): `calories = protein·4 + fat·9 + max(carbs − fiber, 0)·4 + fiber·2`.
- BMI status bands: `<18.5` underweight · `18.5–24.9` normal · `25–29.9` overweight · `≥30` obese.
- Protein goal `1.8 g/kg` current weight. Calorie goal = Mifflin-St Jeor BMR × activity factor.
- localStorage keys are namespaced `luxifit.*`.
- Vitamins is an informational string on a food — displayed, never summed.
- Log items snapshot their macros at log time.

---

### Task 1: Project scaffold + app shell + bottom nav + placeholder routes

**Files:**
- Create: `package.json`, `svelte.config.js`, `vite.config.ts`, `tsconfig.json`, `.npmrc`
- Create: `src/app.html`, `src/app.css`, `src/app.d.ts`
- Create: `src/routes/+layout.ts`, `src/routes/+layout.svelte`, `src/routes/+page.ts`
- Create: `src/routes/food/+page.svelte`, `src/routes/progress/+page.svelte`, `src/routes/workout/+page.svelte`, `src/routes/anatomy/+page.svelte`
- Create: `src/lib/components/BottomNav.svelte`
- Create: `static/manifest.webmanifest`, `static/favicon.png` (placeholder), `static/robots.txt`

**Interfaces:**
- Consumes: nothing.
- Produces: a running dev server; theme CSS variables in `app.css`; `BottomNav.svelte` (no props); route paths `/food`, `/progress`, `/workout`, `/anatomy`.

- [ ] **Step 1: Create `package.json`**

```json
{
  "name": "luxifit",
  "version": "0.1.0",
  "private": true,
  "type": "module",
  "scripts": {
    "dev": "vite dev",
    "build": "vite build",
    "preview": "vite preview",
    "check": "svelte-kit sync && svelte-check --tsconfig ./tsconfig.json",
    "test": "vitest run",
    "test:watch": "vitest"
  },
  "devDependencies": {
    "@sveltejs/adapter-static": "^3.0.6",
    "@sveltejs/kit": "^2.8.0",
    "@sveltejs/vite-plugin-svelte": "^4.0.0",
    "jsdom": "^25.0.1",
    "svelte": "^5.1.0",
    "svelte-check": "^4.0.0",
    "typescript": "^5.6.0",
    "vite": "^5.4.0",
    "vitest": "^2.1.0"
  }
}
```

- [ ] **Step 2: Create config files**

`.npmrc`:
```
engine-strict=false
```

`svelte.config.js`:
```js
import adapter from '@sveltejs/adapter-static';
import { vitePreprocess } from '@sveltejs/vite-plugin-svelte';

/** @type {import('@sveltejs/kit').Config} */
const config = {
  preprocess: vitePreprocess(),
  kit: {
    adapter: adapter({ fallback: 'index.html' })
  }
};
export default config;
```

`vite.config.ts`:
```ts
import { sveltekit } from '@sveltejs/kit/vite';
import { defineConfig } from 'vitest/config';

export default defineConfig({
  plugins: [sveltekit()],
  test: {
    environment: 'jsdom',
    include: ['src/**/*.{test,spec}.ts']
  }
});
```

`tsconfig.json`:
```json
{
  "extends": "./.svelte-kit/tsconfig.json",
  "compilerOptions": {
    "allowJs": true,
    "checkJs": true,
    "esModuleInterop": true,
    "forceConsistentCasingInFileNames": true,
    "resolveJsonModule": true,
    "skipLibCheck": true,
    "sourceMap": true,
    "strict": true,
    "moduleResolution": "bundler"
  }
}
```

`src/app.d.ts`:
```ts
declare global {
  namespace App {}
}
export {};
```

- [ ] **Step 3: Create `src/app.html`**

```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8" />
    <link rel="icon" href="%sveltekit.assets%/favicon.png" />
    <meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover" />
    <meta name="theme-color" content="#0B0B0C" />
    <link rel="manifest" href="%sveltekit.assets%/manifest.webmanifest" />
    %sveltekit.head%
  </head>
  <body data-sveltekit-preload-data="hover">
    <div style="display: contents">%sveltekit.body%</div>
  </body>
</html>
```

- [ ] **Step 4: Create `src/app.css` (theme tokens + base)**

```css
:root {
  --bg: #0B0B0C;
  --surface: #141416;
  --surface-2: #1D1D20;
  --text: #F5F5F5;
  --muted: #9A9A9E;
  --red: #E01E2B;
  --red-dim: #7a1119;
  --radius: 16px;
  --nav-h: 64px;
  --maxw: 480px;
}
* { box-sizing: border-box; }
html, body { margin: 0; padding: 0; background: var(--bg); color: var(--text); }
body {
  font-family: system-ui, -apple-system, "Segoe UI", Roboto, sans-serif;
  -webkit-font-smoothing: antialiased;
}
button { font: inherit; cursor: pointer; }
input, select { font: inherit; }
a { color: inherit; text-decoration: none; }
.app-shell {
  max-width: var(--maxw);
  margin: 0 auto;
  min-height: 100dvh;
  padding-bottom: calc(var(--nav-h) + env(safe-area-inset-bottom));
  position: relative;
}
.screen { padding: 20px 16px; }
.card {
  background: var(--surface);
  border-radius: var(--radius);
  border: 1px solid #232327;
}
.h1 { font-size: 24px; font-weight: 700; margin: 0; }
.h2 { font-size: 18px; font-weight: 600; margin: 0; }
.muted { color: var(--muted); }
.btn-primary {
  background: var(--red); color: #fff; border: none;
  border-radius: 12px; padding: 12px 16px; font-weight: 600;
}
.btn-ghost {
  background: var(--surface-2); color: var(--text); border: 1px solid #2a2a2e;
  border-radius: 12px; padding: 12px 16px; font-weight: 600;
}
.placeholder {
  display: flex; flex-direction: column; align-items: center; justify-content: center;
  min-height: 60dvh; gap: 8px; text-align: center;
}
```

- [ ] **Step 5: Create root layout files (SPA mode)**

`src/routes/+layout.ts`:
```ts
export const ssr = false;
export const prerender = true;
```

`src/routes/+layout.svelte`:
```svelte
<script lang="ts">
  import '../app.css';
  import BottomNav from '$lib/components/BottomNav.svelte';
  let { children } = $props();
</script>

<div class="app-shell">
  {@render children()}
  <BottomNav />
</div>
```

`src/routes/+page.ts` (redirect root to /food):
```ts
import { redirect } from '@sveltejs/kit';
export const load = () => {
  throw redirect(307, '/food');
};
```

- [ ] **Step 6: Create `src/lib/components/BottomNav.svelte`**

```svelte
<script lang="ts">
  import { page } from '$app/stores';
  const tabs = [
    { href: '/food', label: 'Food', icon: '🍽️' },
    { href: '/progress', label: 'Progress', icon: '📈' },
    { href: '/workout', label: 'Workout', icon: '🏋️' },
    { href: '/anatomy', label: 'Anatomy', icon: '🫀' }
  ];
  const active = (href: string, path: string) => path.startsWith(href);
</script>

<nav class="nav">
  {#each tabs as t}
    <a href={t.href} class="tab" class:active={active(t.href, $page.url.pathname)}>
      <span class="icon">{t.icon}</span>
      <span class="lbl">{t.label}</span>
    </a>
  {/each}
</nav>

<style>
  .nav {
    position: fixed; left: 0; right: 0; bottom: 0;
    height: calc(var(--nav-h) + env(safe-area-inset-bottom));
    padding-bottom: env(safe-area-inset-bottom);
    max-width: var(--maxw); margin: 0 auto;
    display: grid; grid-template-columns: repeat(4, 1fr);
    background: var(--surface); border-top: 1px solid #232327;
  }
  .tab {
    display: flex; flex-direction: column; align-items: center; justify-content: center;
    gap: 2px; color: var(--muted); font-size: 11px; font-weight: 600;
  }
  .tab.active { color: var(--red); }
  .icon { font-size: 20px; filter: grayscale(1) brightness(1.6); }
  .tab.active .icon { filter: none; }
</style>
```

- [ ] **Step 7: Create the four route pages**

`src/routes/food/+page.svelte` (temporary stub, replaced in later tasks):
```svelte
<div class="screen"><h1 class="h1">Food</h1><p class="muted">Building…</p></div>
```

`src/routes/progress/+page.svelte`:
```svelte
<div class="screen placeholder">
  <div style="font-size:40px">📈</div>
  <h1 class="h1">Progress</h1>
  <p class="muted">Coming soon</p>
</div>
```

`src/routes/workout/+page.svelte`:
```svelte
<div class="screen placeholder">
  <div style="font-size:40px">🏋️</div>
  <h1 class="h1">Workout</h1>
  <p class="muted">Coming soon</p>
</div>
```

`src/routes/anatomy/+page.svelte`:
```svelte
<div class="screen placeholder">
  <div style="font-size:40px">🫀</div>
  <h1 class="h1">Anatomy</h1>
  <p class="muted">Coming soon</p>
</div>
```

- [ ] **Step 8: Create PWA static files**

`static/manifest.webmanifest`:
```json
{
  "name": "LuxiFit",
  "short_name": "LuxiFit",
  "start_url": "/food",
  "display": "standalone",
  "background_color": "#0B0B0C",
  "theme_color": "#0B0B0C",
  "icons": [
    { "src": "/favicon.png", "sizes": "512x512", "type": "image/png", "purpose": "any" }
  ]
}
```

`static/robots.txt`:
```
User-agent: *
Allow: /
```

Create a placeholder `static/favicon.png` (any small PNG; a real icon is generated in Task 10):
```bash
printf '\x89PNG\r\n\x1a\n' > static/favicon.png
```

- [ ] **Step 9: Install and verify the app runs**

Run:
```bash
npm install
npm run build
```
Expected: install succeeds; `npm run build` completes with no errors (adapter-static emits `build/`).

- [ ] **Step 10: Manual smoke check**

Run: `npm run dev` and open the printed URL.
Expected: dark screen, bottom nav with 4 tabs; `/` redirects to `/food`; tapping Progress/Workout/Anatomy shows "Coming soon"; active tab is red.

- [ ] **Step 11: Commit**

```bash
git add -A
git commit -m "feat: scaffold LuxiFit SvelteKit PWA shell with bottom nav and placeholder tabs"
```

---

### Task 2: Types, id util, persisted-store helper

**Files:**
- Create: `src/lib/types.ts`
- Create: `src/lib/utils/id.ts`
- Create: `src/lib/utils/persist.ts`
- Test: `src/lib/utils/persist.test.ts`

**Interfaces:**
- Consumes: nothing.
- Produces:
  - `types.ts`: `Sex`, `Category`, `Macros`, `Food`, `PlanItem`, `DietPlan`, `LogItem`, `DayLog`, `Profile`.
  - `id.ts`: `newId(): string`.
  - `persist.ts`: `persisted<T>(key: string, initial: T): Writable<T>` (Svelte `Writable`, auto-syncs to `localStorage` when available).

- [ ] **Step 1: Create `src/lib/types.ts`**

```ts
export type Sex = 'male' | 'female';
export type Category =
  | 'protein' | 'carb' | 'veg' | 'dairy' | 'fruit' | 'drink' | 'junk' | 'other';

export interface Macros {
  calories: number; // kcal
  protein: number;  // g
  carbs: number;    // g (total carbohydrate, fiber included)
  fiber: number;    // g
  fats: number;     // g
}

export interface Food {
  id: string;
  name: string;
  category: Category;
  servingLabel: string; // e.g. "1 chapati", "1 cup", "100 g"
  perServing: Macros;
  vitamins?: string;    // informational only, never summed
  isJunk: boolean;
  isDefault: boolean;
}

export interface PlanItem { foodId: string; quantity: number; }
export interface DietPlan { id: string; name: string; items: PlanItem[]; }

export interface LogItem {
  foodId: string;
  name: string;
  quantity: number;
  macros: Macros; // snapshot of scaled macros at log time
}
export interface DayLog { date: string; items: LogItem[]; } // date = YYYY-MM-DD

export interface Profile {
  name?: string;
  age: number;
  sex: Sex;
  heightCm: number;
  currentWeightKg: number;
  targetWeightKg: number;
  activity: number; // Mifflin activity factor
  onboarded: boolean;
}
```

- [ ] **Step 2: Create `src/lib/utils/id.ts`**

```ts
export function newId(): string {
  if (typeof crypto !== 'undefined' && 'randomUUID' in crypto) {
    return crypto.randomUUID();
  }
  return 'id-' + Math.random().toString(36).slice(2) + Date.now().toString(36);
}
```

- [ ] **Step 3: Write the failing test for `persisted`**

`src/lib/utils/persist.test.ts`:
```ts
import { describe, it, expect, beforeEach } from 'vitest';
import { get } from 'svelte/store';
import { persisted } from './persist';

describe('persisted', () => {
  beforeEach(() => localStorage.clear());

  it('uses the initial value when nothing is stored', () => {
    const s = persisted('luxifit.test', { n: 1 });
    expect(get(s)).toEqual({ n: 1 });
  });

  it('writes updates to localStorage', () => {
    const s = persisted<{ n: number }>('luxifit.test', { n: 1 });
    s.set({ n: 5 });
    expect(JSON.parse(localStorage.getItem('luxifit.test')!)).toEqual({ n: 5 });
  });

  it('rehydrates from localStorage on re-create', () => {
    localStorage.setItem('luxifit.test', JSON.stringify({ n: 9 }));
    const s = persisted<{ n: number }>('luxifit.test', { n: 1 });
    expect(get(s)).toEqual({ n: 9 });
  });
});
```

- [ ] **Step 4: Run the test to verify it fails**

Run: `npm test -- persist`
Expected: FAIL — cannot resolve `./persist`.

- [ ] **Step 5: Create `src/lib/utils/persist.ts`**

```ts
import { writable, type Writable } from 'svelte/store';

const hasLS = () => typeof localStorage !== 'undefined';

export function persisted<T>(key: string, initial: T): Writable<T> {
  let start = initial;
  if (hasLS()) {
    const raw = localStorage.getItem(key);
    if (raw !== null) {
      try { start = JSON.parse(raw) as T; } catch { /* keep initial */ }
    }
  }
  const store = writable<T>(start);
  if (hasLS()) {
    store.subscribe((value) => localStorage.setItem(key, JSON.stringify(value)));
  }
  return store;
}
```

- [ ] **Step 6: Run the test to verify it passes**

Run: `npm test -- persist`
Expected: PASS (3 tests).

- [ ] **Step 7: Commit**

```bash
git add src/lib/types.ts src/lib/utils/id.ts src/lib/utils/persist.ts src/lib/utils/persist.test.ts
git commit -m "feat: add domain types, id util, and persisted localStorage store"
```

---

### Task 3: Nutrition math (TDD)

**Files:**
- Create: `src/lib/utils/nutrition.ts`
- Test: `src/lib/utils/nutrition.test.ts`

**Interfaces:**
- Consumes: `Macros`, `Sex` from `$lib/types`.
- Produces (exact signatures):
  - `round1(n: number): number`
  - `bmi(weightKg: number, heightCm: number): number` (1 decimal)
  - `type BmiStatus = 'underweight' | 'normal' | 'overweight' | 'obese'`
  - `bmiStatus(bmiValue: number): BmiStatus`
  - `targetBmi(targetWeightKg: number, heightCm: number): number`
  - `bmr(sex: Sex, weightKg: number, heightCm: number, age: number): number` (Mifflin-St Jeor, rounded int)
  - `tdee(bmrValue: number, activity: number): number` (rounded int)
  - `proteinGoal(weightKg: number): number` (`1.8 g/kg`, rounded int)
  - `caloriesFromMacros(m: Pick<Macros,'protein'|'carbs'|'fiber'|'fats'>): number` (rounded int, per Global Constraints)
  - `scaleMacros(m: Macros, quantity: number): Macros` (each field rounded 1 decimal; calories rounded int)
  - `sumMacros(list: Macros[]): Macros` (calories rounded int, others 1 decimal)

- [ ] **Step 1: Write the failing tests**

`src/lib/utils/nutrition.test.ts`:
```ts
import { describe, it, expect } from 'vitest';
import {
  bmi, bmiStatus, targetBmi, bmr, tdee, proteinGoal,
  caloriesFromMacros, scaleMacros, sumMacros
} from './nutrition';
import type { Macros } from '$lib/types';

describe('bmi', () => {
  it('computes kg / m^2 to one decimal', () => {
    expect(bmi(70, 175)).toBe(22.9);
  });
});

describe('bmiStatus', () => {
  it('classifies bands', () => {
    expect(bmiStatus(17)).toBe('underweight');
    expect(bmiStatus(22)).toBe('normal');
    expect(bmiStatus(27)).toBe('overweight');
    expect(bmiStatus(31)).toBe('obese');
    expect(bmiStatus(18.5)).toBe('normal');
    expect(bmiStatus(25)).toBe('overweight');
  });
});

describe('targetBmi', () => {
  it('is bmi at the target weight', () => {
    expect(targetBmi(65, 175)).toBe(21.2);
  });
});

describe('bmr (Mifflin-St Jeor)', () => {
  it('male', () => {
    expect(bmr('male', 70, 175, 21)).toBe(1649); // 700+1093.75-105+5
  });
  it('female', () => {
    expect(bmr('female', 60, 165, 25)).toBe(1345); // 600+1031.25-125-161
  });
});

describe('tdee', () => {
  it('multiplies bmr by activity, rounded', () => {
    expect(tdee(1649, 1.375)).toBe(2267);
  });
});

describe('proteinGoal', () => {
  it('is 1.8 g/kg rounded', () => {
    expect(proteinGoal(70)).toBe(126);
  });
});

describe('caloriesFromMacros', () => {
  it('subtracts fiber from carbs to avoid double count', () => {
    // p3*4 + fat2.5*9 + (18-2.7)*4 + 2.7*2 = 12+22.5+61.2+5.4 = 101.1 -> 101
    expect(caloriesFromMacros({ protein: 3, carbs: 18, fiber: 2.7, fats: 2.5 })).toBe(101);
  });
  it('clamps digestible carbs at 0 when fiber exceeds carbs', () => {
    // p0 + fat0 + max(2-5,0)*4 + 5*2 = 10
    expect(caloriesFromMacros({ protein: 0, carbs: 2, fiber: 5, fats: 0 })).toBe(10);
  });
});

describe('scaleMacros', () => {
  it('scales every field by quantity', () => {
    const m: Macros = { calories: 100, protein: 3, carbs: 18, fiber: 2, fats: 2.5 };
    expect(scaleMacros(m, 2)).toEqual({ calories: 200, protein: 6, carbs: 36, fiber: 4, fats: 5 });
  });
  it('supports fractional quantity', () => {
    const m: Macros = { calories: 100, protein: 3, carbs: 18, fiber: 2, fats: 2.5 };
    expect(scaleMacros(m, 0.5)).toEqual({ calories: 50, protein: 1.5, carbs: 9, fiber: 1, fats: 1.25 });
  });
});

describe('sumMacros', () => {
  it('adds a list field-wise', () => {
    const a: Macros = { calories: 100, protein: 3, carbs: 18, fiber: 2, fats: 2.5 };
    const b: Macros = { calories: 50, protein: 1.5, carbs: 9, fiber: 1, fats: 1.25 };
    expect(sumMacros([a, b])).toEqual({ calories: 150, protein: 4.5, carbs: 27, fiber: 3, fats: 3.75 });
  });
  it('returns zeros for empty list', () => {
    expect(sumMacros([])).toEqual({ calories: 0, protein: 0, carbs: 0, fiber: 0, fats: 0 });
  });
});
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `npm test -- nutrition`
Expected: FAIL — cannot resolve `./nutrition`.

- [ ] **Step 3: Create `src/lib/utils/nutrition.ts`**

```ts
import type { Macros, Sex } from '$lib/types';

export function round1(n: number): number {
  return Math.round(n * 10) / 10;
}

export function bmi(weightKg: number, heightCm: number): number {
  const m = heightCm / 100;
  return round1(weightKg / (m * m));
}

export type BmiStatus = 'underweight' | 'normal' | 'overweight' | 'obese';

export function bmiStatus(bmiValue: number): BmiStatus {
  if (bmiValue < 18.5) return 'underweight';
  if (bmiValue < 25) return 'normal';
  if (bmiValue < 30) return 'overweight';
  return 'obese';
}

export function targetBmi(targetWeightKg: number, heightCm: number): number {
  return bmi(targetWeightKg, heightCm);
}

export function bmr(sex: Sex, weightKg: number, heightCm: number, age: number): number {
  const base = 10 * weightKg + 6.25 * heightCm - 5 * age;
  return Math.round(base + (sex === 'male' ? 5 : -161));
}

export function tdee(bmrValue: number, activity: number): number {
  return Math.round(bmrValue * activity);
}

export function proteinGoal(weightKg: number): number {
  return Math.round(weightKg * 1.8);
}

export function caloriesFromMacros(
  m: Pick<Macros, 'protein' | 'carbs' | 'fiber' | 'fats'>
): number {
  const digestibleCarbs = Math.max(m.carbs - m.fiber, 0);
  return Math.round(m.protein * 4 + m.fats * 9 + digestibleCarbs * 4 + m.fiber * 2);
}

export function scaleMacros(m: Macros, quantity: number): Macros {
  return {
    calories: Math.round(m.calories * quantity),
    protein: round1(m.protein * quantity),
    carbs: round1(m.carbs * quantity),
    fiber: round1(m.fiber * quantity),
    fats: round1(m.fats * quantity)
  };
}

export function sumMacros(list: Macros[]): Macros {
  const total = list.reduce(
    (acc, m) => ({
      calories: acc.calories + m.calories,
      protein: acc.protein + m.protein,
      carbs: acc.carbs + m.carbs,
      fiber: acc.fiber + m.fiber,
      fats: acc.fats + m.fats
    }),
    { calories: 0, protein: 0, carbs: 0, fiber: 0, fats: 0 }
  );
  return {
    calories: Math.round(total.calories),
    protein: round1(total.protein),
    carbs: round1(total.carbs),
    fiber: round1(total.fiber),
    fats: round1(total.fats)
  };
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `npm test -- nutrition`
Expected: PASS (all cases).

- [ ] **Step 5: Commit**

```bash
git add src/lib/utils/nutrition.ts src/lib/utils/nutrition.test.ts
git commit -m "feat: add nutrition math (bmi, tdee, macro scaling) with tests"
```

---

### Task 4: Seed foods data

**Files:**
- Create: `src/lib/data/seed-foods.ts`
- Test: `src/lib/data/seed-foods.test.ts`

**Interfaces:**
- Consumes: `Food`, `Macros` from `$lib/types`.
- Produces: `seedFoods: Food[]` — the default Tamil-Nadu food database. Each has a stable string `id` (prefixed `seed-`), `isDefault: true`.

- [ ] **Step 1: Write the failing test (data integrity)**

`src/lib/data/seed-foods.test.ts`:
```ts
import { describe, it, expect } from 'vitest';
import { seedFoods } from './seed-foods';

describe('seedFoods', () => {
  it('has at least 45 foods', () => {
    expect(seedFoods.length).toBeGreaterThanOrEqual(45);
  });
  it('has unique ids all prefixed seed-', () => {
    const ids = seedFoods.map((f) => f.id);
    expect(new Set(ids).size).toBe(ids.length);
    expect(ids.every((id) => id.startsWith('seed-'))).toBe(true);
  });
  it('marks every seed as default with non-negative macros', () => {
    for (const f of seedFoods) {
      expect(f.isDefault).toBe(true);
      const m = f.perServing;
      for (const v of [m.calories, m.protein, m.carbs, m.fiber, m.fats]) {
        expect(v).toBeGreaterThanOrEqual(0);
      }
      expect(f.servingLabel.length).toBeGreaterThan(0);
    }
  });
  it('includes at least 6 junk items', () => {
    expect(seedFoods.filter((f) => f.isJunk).length).toBeGreaterThanOrEqual(6);
  });
});
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `npm test -- seed-foods`
Expected: FAIL — cannot resolve `./seed-foods`.

- [ ] **Step 3: Create `src/lib/data/seed-foods.ts`**

```ts
import type { Food, Category } from '$lib/types';

type Seed = [
  name: string, category: Category, serving: string,
  calories: number, protein: number, carbs: number, fiber: number, fats: number,
  junk?: boolean, vitamins?: string
];

const rows: Seed[] = [
  // Protein
  ['Boiled egg', 'protein', '1 egg', 78, 6.3, 0.6, 0, 5.3, false, 'B12, D'],
  ['Egg whites', 'protein', '1 white', 17, 3.6, 0.2, 0, 0.1],
  ['Chicken breast', 'protein', '100 g', 165, 31, 0, 0, 3.6, false, 'B6'],
  ['Fish (sardine)', 'protein', '100 g', 208, 25, 0, 0, 11, false, 'Omega-3, D'],
  ['Fish curry', 'protein', '1 cup', 200, 18, 6, 1, 12],
  ['Chicken curry', 'protein', '1 cup', 240, 20, 6, 1, 15],
  ['Paneer', 'protein', '100 g', 265, 18, 1.2, 0, 21, false, 'Calcium'],
  ['Boiled channa', 'protein', '1 cup', 269, 15, 45, 12, 4, false, 'Iron'],
  ['Moong sprouts', 'protein', '1 cup', 31, 3, 6, 2, 0.2],
  ['Soya chunks (dry)', 'protein', '50 g', 172, 26, 16, 6, 0.5, false, 'Iron'],
  ['Green gram pesarattu', 'protein', '1 dosa', 150, 8, 20, 4, 4],
  // Carb / staples
  ['Idli', 'carb', '1 idli', 58, 2, 12, 0.6, 0.3],
  ['Plain dosa', 'carb', '1 dosa', 133, 2.7, 18, 1, 5.5],
  ['Egg dosa', 'carb', '1 dosa', 200, 8, 18, 1, 11],
  ['Wheat dosa', 'carb', '1 dosa', 120, 3, 20, 3, 3],
  ['Chapati', 'carb', '1 chapati', 104, 3, 18, 2.7, 2.5],
  ['White rice', 'carb', '1 cup', 205, 4.3, 45, 0.6, 0.4],
  ['Brown rice', 'carb', '1 cup', 216, 5, 45, 3.5, 1.8],
  ['Curd rice', 'carb', '1 cup', 197, 6, 30, 1, 6],
  ['Ragi ball', 'carb', '1 ball', 220, 5, 48, 8, 1.5, false, 'Calcium, Iron'],
  ['Oats (dry)', 'carb', '40 g', 152, 5, 27, 4, 3],
  ['Upma', 'carb', '1 cup', 250, 6, 36, 3, 9],
  ['Poha', 'carb', '1 cup', 270, 5, 40, 2, 10],
  ['Ven pongal', 'carb', '1 cup', 285, 8, 40, 3, 10],
  ['Sweet potato', 'carb', '1 medium', 112, 2, 26, 4, 0.1, false, 'Vit A'],
  // Dals / gravies / veg
  ['Sambar', 'veg', '1 cup', 150, 6, 20, 5, 5],
  ['Rasam', 'veg', '1 cup', 65, 2, 10, 2, 2],
  ['Thuvaram paruppu (dal)', 'veg', '1 cup', 190, 12, 28, 8, 3],
  ['Kootu', 'veg', '1 cup', 160, 6, 18, 6, 7],
  // Dairy
  ['Curd', 'dairy', '1 cup', 110, 9, 12, 0, 4, false, 'Calcium'],
  ['Toned milk', 'dairy', '1 cup', 120, 6, 11, 0, 5, false, 'Calcium'],
  ['Buttermilk', 'dairy', '1 glass', 40, 3, 5, 0, 1],
  // Fruit / snacks
  ['Banana', 'fruit', '1 medium', 105, 1.3, 27, 3, 0.4, false, 'B6, Potassium'],
  ['Apple', 'fruit', '1 medium', 95, 0.5, 25, 4, 0.3],
  ['Dates', 'fruit', '2 dates', 133, 1, 36, 3, 0.2, false, 'Iron'],
  ['Peanuts', 'other', '30 g', 170, 7, 5, 2.5, 14],
  ['Almonds', 'other', '10 nuts', 70, 2.5, 2.5, 1.5, 6, false, 'Vit E'],
  // Drinks
  ['Black coffee', 'drink', '1 cup', 5, 0.3, 0, 0, 0],
  ['Tea with sugar', 'drink', '1 cup', 90, 2, 15, 0, 3],
  ['Tender coconut', 'drink', '1 whole', 46, 2, 9, 3, 0.5],
  // Junk
  ['Parotta', 'junk', '1 parotta', 260, 5, 36, 1.5, 11, true],
  ['Chicken biryani', 'junk', '1 plate', 550, 25, 65, 3, 22, true],
  ['Medu vada', 'junk', '1 vada', 130, 4, 15, 2, 6, true],
  ['Bajji', 'junk', '1 piece', 100, 2, 12, 1, 5, true],
  ['Samosa', 'junk', '1 piece', 130, 3, 15, 1.5, 7, true],
  ['Jangiri (sweet)', 'junk', '1 piece', 150, 1, 25, 0, 6, true],
  ['Soft drink', 'junk', '330 ml', 139, 0, 35, 0, 0, true],
  ['Bakery bun', 'junk', '1 bun', 180, 5, 32, 1, 3.5, true]
];

export const seedFoods: Food[] = rows.map(
  ([name, category, servingLabel, calories, protein, carbs, fiber, fats, junk, vitamins], i) => ({
    id: `seed-${i + 1}`,
    name,
    category,
    servingLabel,
    perServing: { calories, protein, carbs, fiber, fats },
    vitamins,
    isJunk: junk ?? false,
    isDefault: true
  })
);
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `npm test -- seed-foods`
Expected: PASS (4 tests).

- [ ] **Step 5: Commit**

```bash
git add src/lib/data/seed-foods.ts src/lib/data/seed-foods.test.ts
git commit -m "feat: add Tamil-Nadu seed food database"
```

---

### Task 5: Stores (profile, foods, plans, log)

**Files:**
- Create: `src/lib/stores/profile.ts`
- Create: `src/lib/stores/foods.ts`
- Create: `src/lib/stores/plans.ts`
- Create: `src/lib/stores/log.ts`
- Test: `src/lib/stores/stores.test.ts`

**Interfaces:**
- Consumes: `persisted` (`$lib/utils/persist`), `newId` (`$lib/utils/id`), `seedFoods` (`$lib/data/seed-foods`), `scaleMacros` (`$lib/utils/nutrition`), all types.
- Produces:
  - `profile.ts`: `DEFAULT_PROFILE: Profile`, `profile: Writable<Profile>`, `saveProfile(p: Profile): void`.
  - `foods.ts`: `foods: Writable<Food[]>`, `addFood(input: Omit<Food,'id'|'isDefault'>): Food`, `updateFood(f: Food): void`, `deleteFood(id: string): void`, `findFood(list: Food[], id: string): Food | undefined`.
  - `plans.ts`: `plans: Writable<DietPlan[]>`, `addPlan(name: string, items: PlanItem[]): DietPlan`, `updatePlan(p: DietPlan): void`, `deletePlan(id: string): void`.
  - `log.ts`: `logMap: Writable<Record<string, DayLog>>`, `todayKey(): string`, `dateKey(d: Date): string`, `getDay(map: Record<string, DayLog>, date: string): DayLog`, `addLogItem(date: string, item: LogItem): void`, `removeLogItem(date: string, index: number): void`, `logItemFromFood(food: Food, quantity: number): LogItem`, `applyPlanToDay(date: string, plan: DietPlan, foods: Food[]): void`.

- [ ] **Step 1: Create `src/lib/stores/profile.ts`**

```ts
import type { Profile } from '$lib/types';
import { persisted } from '$lib/utils/persist';

export const DEFAULT_PROFILE: Profile = {
  age: 21,
  sex: 'male',
  heightCm: 170,
  currentWeightKg: 65,
  targetWeightKg: 65,
  activity: 1.375,
  onboarded: false
};

export const profile = persisted<Profile>('luxifit.profile', DEFAULT_PROFILE);

export function saveProfile(p: Profile): void {
  profile.set({ ...p, onboarded: true });
}
```

- [ ] **Step 2: Create `src/lib/stores/foods.ts`**

```ts
import type { Food } from '$lib/types';
import { persisted } from '$lib/utils/persist';
import { newId } from '$lib/utils/id';
import { seedFoods } from '$lib/data/seed-foods';

export const foods = persisted<Food[]>('luxifit.foods', seedFoods);

export function addFood(input: Omit<Food, 'id' | 'isDefault'>): Food {
  const food: Food = { ...input, id: newId(), isDefault: false };
  foods.update((list) => [food, ...list]);
  return food;
}

export function updateFood(f: Food): void {
  foods.update((list) => list.map((x) => (x.id === f.id ? f : x)));
}

export function deleteFood(id: string): void {
  foods.update((list) => list.filter((x) => x.id !== id));
}

export function findFood(list: Food[], id: string): Food | undefined {
  return list.find((x) => x.id === id);
}
```

- [ ] **Step 3: Create `src/lib/stores/plans.ts`**

```ts
import type { DietPlan, PlanItem } from '$lib/types';
import { persisted } from '$lib/utils/persist';
import { newId } from '$lib/utils/id';

export const plans = persisted<DietPlan[]>('luxifit.plans', []);

export function addPlan(name: string, items: PlanItem[]): DietPlan {
  const plan: DietPlan = { id: newId(), name, items };
  plans.update((list) => [plan, ...list]);
  return plan;
}

export function updatePlan(p: DietPlan): void {
  plans.update((list) => list.map((x) => (x.id === p.id ? p : x)));
}

export function deletePlan(id: string): void {
  plans.update((list) => list.filter((x) => x.id !== id));
}
```

- [ ] **Step 4: Create `src/lib/stores/log.ts`**

```ts
import type { DayLog, DietPlan, Food, LogItem } from '$lib/types';
import { persisted } from '$lib/utils/persist';
import { scaleMacros } from '$lib/utils/nutrition';
import { findFood } from './foods';

export const logMap = persisted<Record<string, DayLog>>('luxifit.log', {});

export function dateKey(d: Date): string {
  const y = d.getFullYear();
  const m = String(d.getMonth() + 1).padStart(2, '0');
  const day = String(d.getDate()).padStart(2, '0');
  return `${y}-${m}-${day}`;
}

export function todayKey(): string {
  return dateKey(new Date());
}

export function getDay(map: Record<string, DayLog>, date: string): DayLog {
  return map[date] ?? { date, items: [] };
}

export function logItemFromFood(food: Food, quantity: number): LogItem {
  return {
    foodId: food.id,
    name: food.name,
    quantity,
    macros: scaleMacros(food.perServing, quantity)
  };
}

export function addLogItem(date: string, item: LogItem): void {
  logMap.update((map) => {
    const day = getDay(map, date);
    return { ...map, [date]: { date, items: [...day.items, item] } };
  });
}

export function removeLogItem(date: string, index: number): void {
  logMap.update((map) => {
    const day = getDay(map, date);
    const items = day.items.filter((_, i) => i !== index);
    return { ...map, [date]: { date, items } };
  });
}

export function applyPlanToDay(date: string, plan: DietPlan, foods: Food[]): void {
  const items = plan.items
    .map((pi) => {
      const food = findFood(foods, pi.foodId);
      return food ? logItemFromFood(food, pi.quantity) : null;
    })
    .filter((x): x is LogItem => x !== null);
  logMap.update((map) => {
    const day = getDay(map, date);
    return { ...map, [date]: { date, items: [...day.items, ...items] } };
  });
}
```

- [ ] **Step 5: Write the store behavior test**

`src/lib/stores/stores.test.ts`:
```ts
import { describe, it, expect, beforeEach } from 'vitest';
import { get } from 'svelte/store';
import { foods, addFood, updateFood, deleteFood } from './foods';
import { seedFoods } from '$lib/data/seed-foods';
import {
  logMap, addLogItem, removeLogItem, logItemFromFood, applyPlanToDay, getDay
} from './log';
import { addPlan } from './plans';

beforeEach(() => {
  localStorage.clear();
  foods.set(seedFoods);
  logMap.set({});
});

describe('foods store', () => {
  it('seeds defaults', () => {
    expect(get(foods).length).toBe(seedFoods.length);
  });
  it('adds a user food at the front, editable and deletable', () => {
    const f = addFood({
      name: 'Test', category: 'other', servingLabel: '1',
      perServing: { calories: 10, protein: 1, carbs: 1, fiber: 0, fats: 0 },
      isJunk: false
    });
    expect(get(foods)[0].name).toBe('Test');
    expect(f.isDefault).toBe(false);
    updateFood({ ...f, name: 'Renamed' });
    expect(get(foods)[0].name).toBe('Renamed');
    deleteFood(f.id);
    expect(get(foods).find((x) => x.id === f.id)).toBeUndefined();
  });
  it('can edit a default food', () => {
    const seed = get(foods).find((x) => x.isDefault)!;
    updateFood({ ...seed, name: 'Edited default' });
    expect(get(foods).find((x) => x.id === seed.id)!.name).toBe('Edited default');
  });
});

describe('log store', () => {
  it('adds and removes items for a date, snapshotting macros', () => {
    const chapati = seedFoods.find((f) => f.name === 'Chapati')!;
    addLogItem('2026-07-14', logItemFromFood(chapati, 3));
    const day = getDay(get(logMap), '2026-07-14');
    expect(day.items.length).toBe(1);
    expect(day.items[0].macros.calories).toBe(312); // 104 * 3
    removeLogItem('2026-07-14', 0);
    expect(getDay(get(logMap), '2026-07-14').items.length).toBe(0);
  });
  it('applies a plan into the day log', () => {
    const idli = seedFoods.find((f) => f.name === 'Idli')!;
    const plan = addPlan('Breakfast', [{ foodId: idli.id, quantity: 4 }]);
    applyPlanToDay('2026-07-14', plan, seedFoods);
    const day = getDay(get(logMap), '2026-07-14');
    expect(day.items[0].macros.calories).toBe(232); // 58 * 4
  });
});
```

- [ ] **Step 6: Run the store test to verify it passes**

Run: `npm test -- stores`
Expected: PASS (all cases). (Implementation already exists from Steps 1–4; this test locks behavior.)

- [ ] **Step 7: Commit**

```bash
git add src/lib/stores src/lib/stores/stores.test.ts
git commit -m "feat: add profile, foods, plans, and daily-log stores"
```

---

### Task 6: Shared UI primitives (Modal, MacroBar, MacroRing)

**Files:**
- Create: `src/lib/components/Modal.svelte`
- Create: `src/lib/components/MacroBar.svelte`
- Create: `src/lib/components/MacroRing.svelte`

**Interfaces:**
- Consumes: nothing (pure presentational).
- Produces:
  - `Modal.svelte`: props `{ open: boolean; title?: string; onclose: () => void; children }`. Renders a bottom-sheet overlay; backdrop click and a close button call `onclose`.
  - `MacroBar.svelte`: props `{ label: string; value: number; goal?: number; unit: string; color?: string }`. A labeled progress bar (`value/goal`), red fill by default.
  - `MacroRing.svelte`: props `{ value: number; goal: number; label: string; unit: string }`. An SVG ring showing `value/goal`.

- [ ] **Step 1: Create `src/lib/components/Modal.svelte`**

```svelte
<script lang="ts">
  let { open = false, title = '', onclose, children } = $props<{
    open?: boolean; title?: string; onclose: () => void; children: any;
  }>();
</script>

{#if open}
  <div class="backdrop" onclick={onclose} role="presentation">
    <div class="sheet" onclick={(e) => e.stopPropagation()} role="dialog" aria-modal="true">
      <div class="sheet-head">
        <h2 class="h2">{title}</h2>
        <button class="x" onclick={onclose} aria-label="Close">✕</button>
      </div>
      <div class="sheet-body">
        {@render children()}
      </div>
    </div>
  </div>
{/if}

<style>
  .backdrop {
    position: fixed; inset: 0; background: rgba(0,0,0,0.6);
    display: flex; align-items: flex-end; justify-content: center; z-index: 50;
  }
  .sheet {
    background: var(--surface); width: 100%; max-width: var(--maxw);
    border-radius: 20px 20px 0 0; border: 1px solid #232327;
    max-height: 88dvh; display: flex; flex-direction: column;
  }
  .sheet-head {
    display: flex; align-items: center; justify-content: space-between;
    padding: 16px; border-bottom: 1px solid #232327;
  }
  .sheet-body { padding: 16px; overflow-y: auto; }
  .x { background: none; border: none; color: var(--muted); font-size: 18px; }
</style>
```

- [ ] **Step 2: Create `src/lib/components/MacroBar.svelte`**

```svelte
<script lang="ts">
  let { label, value, goal, unit, color = 'var(--red)' } = $props<{
    label: string; value: number; goal?: number; unit: string; color?: string;
  }>();
  const pct = $derived(goal && goal > 0 ? Math.min((value / goal) * 100, 100) : 0);
</script>

<div class="row">
  <div class="top">
    <span>{label}</span>
    <span class="muted">{value}{goal ? ` / ${goal}` : ''} {unit}</span>
  </div>
  {#if goal}
    <div class="track"><div class="fill" style="width:{pct}%; background:{color}"></div></div>
  {/if}
</div>

<style>
  .row { display: flex; flex-direction: column; gap: 6px; }
  .top { display: flex; justify-content: space-between; font-size: 13px; font-weight: 600; }
  .track { height: 8px; background: var(--surface-2); border-radius: 6px; overflow: hidden; }
  .fill { height: 100%; border-radius: 6px; transition: width 0.25s ease; }
</style>
```

- [ ] **Step 3: Create `src/lib/components/MacroRing.svelte`**

```svelte
<script lang="ts">
  let { value, goal, label, unit } = $props<{
    value: number; goal: number; label: string; unit: string;
  }>();
  const r = 46;
  const circ = 2 * Math.PI * r;
  const pct = $derived(goal > 0 ? Math.min(value / goal, 1) : 0);
  const dash = $derived(circ * pct);
</script>

<div class="ring">
  <svg viewBox="0 0 110 110" width="120" height="120">
    <circle cx="55" cy="55" r={r} fill="none" stroke="var(--surface-2)" stroke-width="10" />
    <circle
      cx="55" cy="55" r={r} fill="none" stroke="var(--red)" stroke-width="10"
      stroke-linecap="round" stroke-dasharray="{dash} {circ}"
      transform="rotate(-90 55 55)"
    />
    <text x="55" y="52" text-anchor="middle" fill="var(--text)" font-size="20" font-weight="700">{value}</text>
    <text x="55" y="70" text-anchor="middle" fill="var(--muted)" font-size="10">/ {goal} {unit}</text>
  </svg>
  <span class="lbl">{label}</span>
</div>

<style>
  .ring { display: flex; flex-direction: column; align-items: center; gap: 4px; }
  .lbl { font-size: 13px; font-weight: 600; color: var(--muted); }
</style>
```

- [ ] **Step 4: Typecheck**

Run: `npm run check`
Expected: no errors.

- [ ] **Step 5: Commit**

```bash
git add src/lib/components/Modal.svelte src/lib/components/MacroBar.svelte src/lib/components/MacroRing.svelte
git commit -m "feat: add Modal, MacroBar, MacroRing UI primitives"
```

---

### Task 7: Onboarding + Profile/BMI header

**Files:**
- Create: `src/lib/components/ProfileForm.svelte`
- Create: `src/lib/components/BmiCard.svelte`
- Modify: `src/routes/food/+page.svelte` (replace stub; gate on onboarding, show BMI header)

**Interfaces:**
- Consumes: `profile`, `saveProfile`, `DEFAULT_PROFILE` (`$lib/stores/profile`); `bmi`, `bmiStatus`, `targetBmi`, `bmr`, `tdee`, `proteinGoal` (`$lib/utils/nutrition`); `Modal`, `MacroBar`.
- Produces:
  - `ProfileForm.svelte`: props `{ initial: Profile; onsave: (p: Profile) => void }`. Numeric/select inputs for age, sex, height, current & target weight, activity; Save button calls `onsave`.
  - `BmiCard.svelte`: props `{ profile: Profile; onedit: () => void }`. Shows BMI, status pill, target BMI + delta, calorie & protein goals; edit button.

- [ ] **Step 1: Create `src/lib/components/ProfileForm.svelte`**

```svelte
<script lang="ts">
  import type { Profile } from '$lib/types';
  let { initial, onsave } = $props<{ initial: Profile; onsave: (p: Profile) => void }>();
  let p = $state<Profile>({ ...initial });
  const activityOptions = [
    { v: 1.2, l: 'Sedentary' },
    { v: 1.375, l: 'Light' },
    { v: 1.55, l: 'Moderate' },
    { v: 1.725, l: 'Very active' }
  ];
  function submit() {
    onsave({ ...p });
  }
</script>

<div class="form">
  <label>Age<input type="number" min="10" max="100" bind:value={p.age} /></label>
  <label>Sex
    <select bind:value={p.sex}>
      <option value="male">Male</option>
      <option value="female">Female</option>
    </select>
  </label>
  <label>Height (cm)<input type="number" min="100" max="230" bind:value={p.heightCm} /></label>
  <label>Current weight (kg)<input type="number" min="25" max="250" step="0.1" bind:value={p.currentWeightKg} /></label>
  <label>Target weight (kg)<input type="number" min="25" max="250" step="0.1" bind:value={p.targetWeightKg} /></label>
  <label>Activity
    <select bind:value={p.activity}>
      {#each activityOptions as o}<option value={o.v}>{o.l}</option>{/each}
    </select>
  </label>
  <button class="btn-primary" onclick={submit}>Save</button>
</div>

<style>
  .form { display: flex; flex-direction: column; gap: 14px; }
  label { display: flex; flex-direction: column; gap: 6px; font-size: 13px; font-weight: 600; color: var(--muted); }
  input, select {
    background: var(--surface-2); color: var(--text); border: 1px solid #2a2a2e;
    border-radius: 10px; padding: 12px; font-size: 16px;
  }
</style>
```

- [ ] **Step 2: Create `src/lib/components/BmiCard.svelte`**

```svelte
<script lang="ts">
  import type { Profile } from '$lib/types';
  import { bmi, bmiStatus, targetBmi, bmr, tdee, proteinGoal } from '$lib/utils/nutrition';
  let { profile, onedit } = $props<{ profile: Profile; onedit: () => void }>();

  const value = $derived(bmi(profile.currentWeightKg, profile.heightCm));
  const status = $derived(bmiStatus(value));
  const target = $derived(targetBmi(profile.targetWeightKg, profile.heightCm));
  const calGoal = $derived(tdee(bmr(profile.sex, profile.currentWeightKg, profile.heightCm, profile.age), profile.activity));
  const protGoal = $derived(proteinGoal(profile.currentWeightKg));
</script>

<div class="card bmi">
  <div class="line">
    <div>
      <div class="big">{value}</div>
      <div class="muted">BMI</div>
    </div>
    <span class="pill {status}">{status}</span>
    <button class="edit" onclick={onedit} aria-label="Edit profile">⚙️</button>
  </div>
  <div class="stats">
    <div><span class="muted">Target BMI</span><b>{target}</b></div>
    <div><span class="muted">Calorie goal</span><b>{calGoal}</b></div>
    <div><span class="muted">Protein goal</span><b>{protGoal} g</b></div>
  </div>
</div>

<style>
  .bmi { padding: 16px; display: flex; flex-direction: column; gap: 14px; }
  .line { display: flex; align-items: center; gap: 14px; }
  .big { font-size: 34px; font-weight: 800; line-height: 1; }
  .pill { padding: 4px 10px; border-radius: 999px; font-size: 12px; font-weight: 700; text-transform: capitalize; }
  .pill.normal { background: #14351f; color: #4ade80; }
  .pill.underweight { background: #10263b; color: #60a5fa; }
  .pill.overweight { background: #3a2a10; color: #fbbf24; }
  .pill.obese { background: var(--red-dim); color: #fca5a5; }
  .edit { margin-left: auto; background: none; border: none; font-size: 18px; }
  .stats { display: grid; grid-template-columns: repeat(3, 1fr); gap: 8px; }
  .stats div { display: flex; flex-direction: column; gap: 2px; font-size: 13px; }
  .stats .muted { font-size: 11px; }
</style>
```

- [ ] **Step 3: Replace `src/routes/food/+page.svelte` with onboarding gate + header (segments added in Task 8)**

```svelte
<script lang="ts">
  import { profile, saveProfile, DEFAULT_PROFILE } from '$lib/stores/profile';
  import ProfileForm from '$lib/components/ProfileForm.svelte';
  import BmiCard from '$lib/components/BmiCard.svelte';
  import Modal from '$lib/components/Modal.svelte';

  let editing = $state(false);
</script>

{#if !$profile.onboarded}
  <div class="screen">
    <h1 class="h1">Welcome to LuxiFit</h1>
    <p class="muted">Set up your profile to get started.</p>
    <div style="margin-top:16px">
      <ProfileForm initial={DEFAULT_PROFILE} onsave={(p) => saveProfile(p)} />
    </div>
  </div>
{:else}
  <div class="screen">
    <h1 class="h1">Food</h1>
    <div style="margin-top:12px">
      <BmiCard profile={$profile} onedit={() => (editing = true)} />
    </div>
  </div>

  <Modal open={editing} title="Edit profile" onclose={() => (editing = false)}>
    <ProfileForm initial={$profile} onsave={(p) => { saveProfile(p); editing = false; }} />
  </Modal>
{/if}
```

- [ ] **Step 4: Typecheck**

Run: `npm run check`
Expected: no errors.

- [ ] **Step 5: Manual verification**

Run: `npm run dev`. On the Food tab (fresh browser / cleared storage):
- Onboarding form shows. Fill values, Save → BMI card appears with computed BMI, a status pill, target BMI, calorie & protein goals.
- Tap ⚙️ → modal with the form pre-filled; change weight, Save → BMI updates.
Expected: all above true.

- [ ] **Step 6: Commit**

```bash
git add src/lib/components/ProfileForm.svelte src/lib/components/BmiCard.svelte src/routes/food/+page.svelte
git commit -m "feat: add onboarding, profile editing, and BMI/goals header"
```

---

### Task 8: Foods segment + Today segment + segmented control

**Files:**
- Create: `src/lib/components/SegmentedControl.svelte`
- Create: `src/lib/components/FoodCard.svelte`
- Create: `src/lib/components/FoodForm.svelte`
- Create: `src/lib/components/FoodPicker.svelte`
- Create: `src/lib/components/Fab.svelte`
- Create: `src/lib/components/FoodsSegment.svelte`
- Create: `src/lib/components/TodaySegment.svelte`
- Modify: `src/routes/food/+page.svelte` (mount segmented control + segments)

**Interfaces:**
- Consumes: stores `foods`/`addFood`/`updateFood`/`deleteFood`, `log` helpers, `profile`; utils `caloriesFromMacros`, `sumMacros`, `bmr`/`tdee`/`proteinGoal`; components `Modal`, `MacroBar`, `MacroRing`.
- Produces:
  - `SegmentedControl.svelte`: props `{ options: string[]; value: string; onchange: (v: string) => void }`.
  - `FoodCard.svelte`: props `{ food: Food; onpick?: () => void; onedit?: () => void }`.
  - `FoodForm.svelte`: props `{ initial?: Food | null; onsave: (f: FoodDraft) => void; ondelete?: () => void }` where `FoodDraft = Omit<Food,'id'|'isDefault'>`. Auto-fills calories via `caloriesFromMacros` unless the user overrides.
  - `FoodPicker.svelte`: props `{ onadd: (foodId: string, quantity: number) => void }` — search list + quantity input.
  - `Fab.svelte`: props `{ onclick: () => void; label?: string }`.
  - `FoodsSegment.svelte`, `TodaySegment.svelte`: no props (read stores directly).

- [ ] **Step 1: Create `src/lib/components/SegmentedControl.svelte`**

```svelte
<script lang="ts">
  let { options, value, onchange } = $props<{
    options: string[]; value: string; onchange: (v: string) => void;
  }>();
</script>

<div class="seg">
  {#each options as o}
    <button class="opt" class:active={o === value} onclick={() => onchange(o)}>{o}</button>
  {/each}
</div>

<style>
  .seg { display: grid; grid-auto-flow: column; gap: 4px; background: var(--surface-2); padding: 4px; border-radius: 12px; }
  .opt { background: none; border: none; color: var(--muted); padding: 10px; border-radius: 9px; font-weight: 600; font-size: 14px; }
  .opt.active { background: var(--red); color: #fff; }
</style>
```

- [ ] **Step 2: Create `src/lib/components/Fab.svelte`**

```svelte
<script lang="ts">
  let { onclick, label = '+' } = $props<{ onclick: () => void; label?: string }>();
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
```

- [ ] **Step 3: Create `src/lib/components/FoodCard.svelte`**

```svelte
<script lang="ts">
  import type { Food } from '$lib/types';
  let { food, onpick, onedit } = $props<{ food: Food; onpick?: () => void; onedit?: () => void }>();
</script>

<div class="fcard card">
  <button class="main" onclick={onpick}>
    <div class="name">{food.name} {#if food.isJunk}<span class="junk">junk</span>{/if}</div>
    <div class="muted sub">{food.servingLabel} · {food.perServing.calories} kcal</div>
    <div class="macros muted">P {food.perServing.protein} · C {food.perServing.carbs} · Fb {food.perServing.fiber} · F {food.perServing.fats}</div>
    {#if food.vitamins}<div class="vits">💊 {food.vitamins}</div>{/if}
  </button>
  {#if onedit}<button class="edit" onclick={onedit} aria-label="Edit food">✎</button>{/if}
</div>

<style>
  .fcard { padding: 12px; display: flex; align-items: flex-start; gap: 8px; }
  .main { background: none; border: none; text-align: left; color: var(--text); flex: 1; display: flex; flex-direction: column; gap: 4px; }
  .name { font-weight: 700; font-size: 15px; }
  .sub { font-size: 12px; }
  .macros { font-size: 12px; }
  .vits { font-size: 11px; color: #a78bfa; }
  .junk { background: var(--red-dim); color: #fca5a5; font-size: 10px; padding: 1px 6px; border-radius: 6px; margin-left: 4px; }
  .edit { background: var(--surface-2); border: 1px solid #2a2a2e; color: var(--muted); border-radius: 8px; width: 32px; height: 32px; }
</style>
```

- [ ] **Step 4: Create `src/lib/components/FoodForm.svelte`**

```svelte
<script lang="ts">
  import type { Food, Category, Macros } from '$lib/types';
  import { caloriesFromMacros } from '$lib/utils/nutrition';

  type FoodDraft = Omit<Food, 'id' | 'isDefault'>;
  let { initial = null, onsave, ondelete } = $props<{
    initial?: Food | null; onsave: (f: FoodDraft) => void; ondelete?: () => void;
  }>();

  const categories: Category[] = ['protein','carb','veg','dairy','fruit','drink','junk','other'];

  let name = $state(initial?.name ?? '');
  let category = $state<Category>(initial?.category ?? 'other');
  let servingLabel = $state(initial?.servingLabel ?? '1 serving');
  let protein = $state(initial?.perServing.protein ?? 0);
  let carbs = $state(initial?.perServing.carbs ?? 0);
  let fiber = $state(initial?.perServing.fiber ?? 0);
  let fats = $state(initial?.perServing.fats ?? 0);
  let vitamins = $state(initial?.vitamins ?? '');
  let isJunk = $state(initial?.isJunk ?? false);
  let calOverride = $state<number | null>(initial ? initial.perServing.calories : null);

  const autoCal = $derived(caloriesFromMacros({ protein, carbs, fiber, fats }));
  const calories = $derived(calOverride ?? autoCal);

  function save() {
    if (!name.trim()) return;
    const perServing: Macros = { calories, protein, carbs, fiber, fats };
    onsave({ name: name.trim(), category, servingLabel, perServing, vitamins: vitamins || undefined, isJunk });
  }
</script>

<div class="form">
  <label>Name<input bind:value={name} placeholder="e.g. Chapati" /></label>
  <label>Serving<input bind:value={servingLabel} placeholder="1 chapati" /></label>
  <label>Category
    <select bind:value={category}>{#each categories as c}<option value={c}>{c}</option>{/each}</select>
  </label>
  <div class="grid">
    <label>Protein (g)<input type="number" step="0.1" bind:value={protein} /></label>
    <label>Carbs (g)<input type="number" step="0.1" bind:value={carbs} /></label>
    <label>Fiber (g)<input type="number" step="0.1" bind:value={fiber} /></label>
    <label>Fats (g)<input type="number" step="0.1" bind:value={fats} /></label>
  </div>
  <label>Calories (kcal)
    <input type="number" bind:value={calOverride} placeholder={String(autoCal)} />
    <small class="muted">Auto from macros: {autoCal} — leave blank to use it.</small>
  </label>
  <label>Vitamins / notes<input bind:value={vitamins} placeholder="Iron, B12 (optional)" /></label>
  <label class="check"><input type="checkbox" bind:checked={isJunk} /> Mark as junk</label>
  <div class="actions">
    <button class="btn-primary" onclick={save}>Save food</button>
    {#if ondelete}<button class="btn-ghost" onclick={ondelete}>Delete</button>{/if}
  </div>
</div>

<style>
  .form { display: flex; flex-direction: column; gap: 12px; }
  .grid { display: grid; grid-template-columns: 1fr 1fr; gap: 10px; }
  label { display: flex; flex-direction: column; gap: 6px; font-size: 13px; font-weight: 600; color: var(--muted); }
  input, select { background: var(--surface-2); color: var(--text); border: 1px solid #2a2a2e; border-radius: 10px; padding: 11px; font-size: 16px; }
  .check { flex-direction: row; align-items: center; gap: 8px; }
  .check input { width: auto; }
  .actions { display: flex; gap: 10px; }
  .actions .btn-primary { flex: 1; }
  small { font-weight: 500; }
</style>
```

- [ ] **Step 5: Create `src/lib/components/FoodPicker.svelte`**

```svelte
<script lang="ts">
  import { foods } from '$lib/stores/foods';
  import FoodCard from './FoodCard.svelte';
  import type { Food } from '$lib/types';

  let { onadd } = $props<{ onadd: (foodId: string, quantity: number) => void }>();
  let query = $state('');
  let selected = $state<Food | null>(null);
  let quantity = $state(1);

  const results = $derived(
    $foods.filter((f) => f.name.toLowerCase().includes(query.toLowerCase()))
  );
  function confirm() {
    if (selected && quantity > 0) onadd(selected.id, quantity);
  }
</script>

{#if !selected}
  <input class="search" placeholder="Search foods…" bind:value={query} />
  <div class="list">
    {#each results as f (f.id)}
      <FoodCard food={f} onpick={() => (selected = f)} />
    {/each}
    {#if results.length === 0}<p class="muted">No matches.</p>{/if}
  </div>
{:else}
  <div class="qty">
    <div class="h2">{selected.name}</div>
    <p class="muted">{selected.servingLabel} · {selected.perServing.calories} kcal each</p>
    <label>Quantity (servings)
      <input type="number" min="0.25" step="0.25" bind:value={quantity} />
    </label>
    <div class="actions">
      <button class="btn-ghost" onclick={() => (selected = null)}>Back</button>
      <button class="btn-primary" onclick={confirm}>Add to today</button>
    </div>
  </div>
{/if}

<style>
  .search { width: 100%; background: var(--surface-2); color: var(--text); border: 1px solid #2a2a2e; border-radius: 10px; padding: 12px; font-size: 16px; margin-bottom: 12px; }
  .list { display: flex; flex-direction: column; gap: 8px; }
  .qty { display: flex; flex-direction: column; gap: 12px; }
  label { display: flex; flex-direction: column; gap: 6px; font-size: 13px; font-weight: 600; color: var(--muted); }
  .qty input { background: var(--surface-2); color: var(--text); border: 1px solid #2a2a2e; border-radius: 10px; padding: 12px; font-size: 16px; }
  .actions { display: flex; gap: 10px; }
  .actions .btn-primary { flex: 1; }
</style>
```

- [ ] **Step 6: Create `src/lib/components/FoodsSegment.svelte`**

```svelte
<script lang="ts">
  import { foods, addFood, updateFood, deleteFood } from '$lib/stores/foods';
  import type { Food, Category } from '$lib/types';
  import FoodCard from './FoodCard.svelte';
  import FoodForm from './FoodForm.svelte';
  import Modal from './Modal.svelte';
  import Fab from './Fab.svelte';

  const filters: (Category | 'all')[] = ['all','protein','carb','veg','dairy','fruit','drink','junk','other'];
  let filter = $state<Category | 'all'>('all');
  let query = $state('');
  let editing = $state<Food | null>(null);
  let creating = $state(false);

  const shown = $derived(
    $foods.filter((f) => {
      const matchQ = f.name.toLowerCase().includes(query.toLowerCase());
      const matchF = filter === 'all' ? true : filter === 'junk' ? f.isJunk : f.category === filter;
      return matchQ && matchF;
    })
  );
</script>

<input class="search" placeholder="Search foods…" bind:value={query} />
<div class="chips">
  {#each filters as f}
    <button class="chip" class:active={f === filter} onclick={() => (filter = f)}>{f}</button>
  {/each}
</div>

<div class="list">
  {#each shown as f (f.id)}
    <FoodCard food={f} onedit={() => (editing = f)} />
  {/each}
</div>

<Fab onclick={() => (creating = true)} />

<Modal open={creating} title="Add food" onclose={() => (creating = false)}>
  <FoodForm onsave={(d) => { addFood(d); creating = false; }} />
</Modal>

<Modal open={!!editing} title="Edit food" onclose={() => (editing = null)}>
  {#if editing}
    <FoodForm
      initial={editing}
      onsave={(d) => { updateFood({ ...editing!, ...d }); editing = null; }}
      ondelete={() => { deleteFood(editing!.id); editing = null; }}
    />
  {/if}
</Modal>

<style>
  .search { width: 100%; background: var(--surface-2); color: var(--text); border: 1px solid #2a2a2e; border-radius: 10px; padding: 12px; font-size: 16px; margin-bottom: 12px; }
  .chips { display: flex; gap: 6px; overflow-x: auto; padding-bottom: 12px; }
  .chip { background: var(--surface-2); border: 1px solid #2a2a2e; color: var(--muted); border-radius: 999px; padding: 6px 12px; font-size: 12px; font-weight: 600; white-space: nowrap; text-transform: capitalize; }
  .chip.active { background: var(--red); color: #fff; border-color: var(--red); }
  .list { display: flex; flex-direction: column; gap: 8px; padding-bottom: 90px; }
</style>
```

- [ ] **Step 7: Create `src/lib/components/TodaySegment.svelte`**

```svelte
<script lang="ts">
  import { profile } from '$lib/stores/profile';
  import { foods, findFood } from '$lib/stores/foods';
  import { logMap, todayKey, getDay, addLogItem, removeLogItem, logItemFromFood } from '$lib/stores/log';
  import { sumMacros, bmr, tdee, proteinGoal } from '$lib/utils/nutrition';
  import MacroRing from './MacroRing.svelte';
  import MacroBar from './MacroBar.svelte';
  import Modal from './Modal.svelte';
  import Fab from './Fab.svelte';
  import FoodPicker from './FoodPicker.svelte';

  const date = todayKey();
  let picking = $state(false);

  const day = $derived(getDay($logMap, date));
  const totals = $derived(sumMacros(day.items.map((i) => i.macros)));
  const calGoal = $derived(tdee(bmr($profile.sex, $profile.currentWeightKg, $profile.heightCm, $profile.age), $profile.activity));
  const protGoal = $derived(proteinGoal($profile.currentWeightKg));

  function add(foodId: string, quantity: number) {
    const food = findFood($foods, foodId);
    if (food) addLogItem(date, logItemFromFood(food, quantity));
    picking = false;
  }
</script>

<div class="rings card">
  <MacroRing value={totals.calories} goal={calGoal} label="Calories" unit="kcal" />
  <MacroRing value={totals.protein} goal={protGoal} label="Protein" unit="g" />
</div>

<div class="card bars">
  <MacroBar label="Carbs" value={totals.carbs} unit="g" />
  <MacroBar label="Fiber" value={totals.fiber} unit="g" />
  <MacroBar label="Fats" value={totals.fats} unit="g" />
</div>

<h2 class="h2" style="margin-top:8px">Today's food</h2>
<div class="items">
  {#each day.items as item, i (i)}
    <div class="item card">
      <div>
        <div class="iname">{item.name} <span class="muted">×{item.quantity}</span></div>
        <div class="muted im">{item.macros.calories} kcal · P {item.macros.protein} · C {item.macros.carbs} · F {item.macros.fats}</div>
      </div>
      <button class="rm" onclick={() => removeLogItem(date, i)} aria-label="Remove">✕</button>
    </div>
  {/each}
  {#if day.items.length === 0}<p class="muted">Nothing logged yet. Tap + to add food.</p>{/if}
</div>

<Fab onclick={() => (picking = true)} />

<Modal open={picking} title="Add food" onclose={() => (picking = false)}>
  <FoodPicker onadd={add} />
</Modal>

<style>
  .rings { display: flex; justify-content: space-around; padding: 16px; margin-bottom: 12px; }
  .bars { padding: 16px; display: flex; flex-direction: column; gap: 12px; }
  .items { display: flex; flex-direction: column; gap: 8px; margin-top: 8px; padding-bottom: 90px; }
  .item { padding: 12px; display: flex; align-items: center; justify-content: space-between; }
  .iname { font-weight: 700; font-size: 14px; }
  .im { font-size: 12px; }
  .rm { background: var(--surface-2); border: 1px solid #2a2a2e; color: var(--muted); border-radius: 8px; width: 32px; height: 32px; }
</style>
```

- [ ] **Step 8: Wire segments into `src/routes/food/+page.svelte`**

Replace the file with:
```svelte
<script lang="ts">
  import { profile, saveProfile, DEFAULT_PROFILE } from '$lib/stores/profile';
  import ProfileForm from '$lib/components/ProfileForm.svelte';
  import BmiCard from '$lib/components/BmiCard.svelte';
  import Modal from '$lib/components/Modal.svelte';
  import SegmentedControl from '$lib/components/SegmentedControl.svelte';
  import TodaySegment from '$lib/components/TodaySegment.svelte';
  import FoodsSegment from '$lib/components/FoodsSegment.svelte';
  import PlansSegment from '$lib/components/PlansSegment.svelte';

  let editing = $state(false);
  let segment = $state('Today');
  const segments = ['Today', 'Foods', 'Plans'];
</script>

{#if !$profile.onboarded}
  <div class="screen">
    <h1 class="h1">Welcome to LuxiFit</h1>
    <p class="muted">Set up your profile to get started.</p>
    <div style="margin-top:16px">
      <ProfileForm initial={DEFAULT_PROFILE} onsave={(p) => saveProfile(p)} />
    </div>
  </div>
{:else}
  <div class="screen">
    <div class="head">
      <h1 class="h1">Food</h1>
    </div>
    <BmiCard profile={$profile} onedit={() => (editing = true)} />
    <div style="margin:14px 0">
      <SegmentedControl options={segments} value={segment} onchange={(v) => (segment = v)} />
    </div>

    {#if segment === 'Today'}<TodaySegment />
    {:else if segment === 'Foods'}<FoodsSegment />
    {:else}<PlansSegment />{/if}
  </div>

  <Modal open={editing} title="Edit profile" onclose={() => (editing = false)}>
    <ProfileForm initial={$profile} onsave={(p) => { saveProfile(p); editing = false; }} />
  </Modal>
{/if}

<style>
  .head { margin-bottom: 12px; }
</style>
```

> Note: `PlansSegment` is created in Task 9. To typecheck Task 8 in isolation, temporarily create `src/lib/components/PlansSegment.svelte` containing `<p class="muted">Plans coming next.</p>` — Task 9 replaces it.

- [ ] **Step 9: Create the temporary PlansSegment stub**

`src/lib/components/PlansSegment.svelte`:
```svelte
<p class="muted">Plans coming next.</p>
```

- [ ] **Step 10: Typecheck**

Run: `npm run check`
Expected: no errors.

- [ ] **Step 11: Manual verification**

Run: `npm run dev`.
- **Today:** rings show 0 / goals; tap FAB → search → pick a food → set quantity → Add → item appears, rings/bars update; remove item works.
- **Foods:** grid lists ~48 seeds; search filters; category chips incl. Junk filter; FAB → add a food (calories auto-fill from macros) → appears at top; edit a default food's macros → persists; delete a food.
Expected: all above true, data survives page reload.

- [ ] **Step 12: Commit**

```bash
git add src/lib/components/SegmentedControl.svelte src/lib/components/FoodCard.svelte src/lib/components/FoodForm.svelte src/lib/components/FoodPicker.svelte src/lib/components/Fab.svelte src/lib/components/FoodsSegment.svelte src/lib/components/TodaySegment.svelte src/lib/components/PlansSegment.svelte src/routes/food/+page.svelte
git commit -m "feat: add Today and Foods segments with picker, food CRUD, macro totals"
```

---

### Task 9: Plans segment (build + apply diet plans)

**Files:**
- Create: `src/lib/components/PlanForm.svelte`
- Modify: `src/lib/components/PlansSegment.svelte` (replace stub with full implementation)

**Interfaces:**
- Consumes: `plans`/`addPlan`/`updatePlan`/`deletePlan`; `foods`/`findFood`; `applyPlanToDay`/`todayKey`; `scaleMacros`/`sumMacros`; `Modal`, `Fab`, `FoodPicker`.
- Produces:
  - `PlanForm.svelte`: props `{ initial?: DietPlan | null; onsave: (name: string, items: PlanItem[]) => void; ondelete?: () => void }`. Name field + add-item (reuse FoodPicker) + item list with remove + running total.

- [ ] **Step 1: Create `src/lib/components/PlanForm.svelte`**

```svelte
<script lang="ts">
  import type { DietPlan, PlanItem } from '$lib/types';
  import { foods, findFood } from '$lib/stores/foods';
  import { scaleMacros, sumMacros } from '$lib/utils/nutrition';
  import Modal from './Modal.svelte';
  import FoodPicker from './FoodPicker.svelte';

  let { initial = null, onsave, ondelete } = $props<{
    initial?: DietPlan | null;
    onsave: (name: string, items: PlanItem[]) => void;
    ondelete?: () => void;
  }>();

  let name = $state(initial?.name ?? '');
  let items = $state<PlanItem[]>(initial ? [...initial.items] : []);
  let picking = $state(false);

  const rows = $derived(
    items.map((it) => {
      const food = findFood($foods, it.foodId);
      return { it, food, macros: food ? scaleMacros(food.perServing, it.quantity) : null };
    })
  );
  const total = $derived(sumMacros(rows.map((r) => r.macros).filter((m) => m !== null) as any));

  function addItem(foodId: string, quantity: number) {
    items = [...items, { foodId, quantity }];
    picking = false;
  }
  function removeItem(i: number) { items = items.filter((_, idx) => idx !== i); }
  function save() { if (name.trim() && items.length) onsave(name.trim(), items); }
</script>

<div class="form">
  <label>Plan name<input bind:value={name} placeholder="e.g. Cut Day" /></label>

  <div class="rows">
    {#each rows as r, i (i)}
      <div class="prow card">
        <div>
          <div class="pn">{r.food?.name ?? 'Deleted food'} <span class="muted">×{r.it.quantity}</span></div>
          {#if r.macros}<div class="muted pm">{r.macros.calories} kcal · P {r.macros.protein}</div>{/if}
        </div>
        <button class="rm" onclick={() => removeItem(i)} aria-label="Remove">✕</button>
      </div>
    {/each}
    {#if items.length === 0}<p class="muted">No foods yet.</p>{/if}
  </div>

  <div class="total muted">Total: {total.calories} kcal · P {total.protein} · C {total.carbs} · F {total.fats}</div>

  <button class="btn-ghost" onclick={() => (picking = true)}>+ Add food to plan</button>
  <div class="actions">
    <button class="btn-primary" onclick={save}>Save plan</button>
    {#if ondelete}<button class="btn-ghost" onclick={ondelete}>Delete</button>{/if}
  </div>
</div>

<Modal open={picking} title="Add to plan" onclose={() => (picking = false)}>
  <FoodPicker onadd={addItem} />
</Modal>

<style>
  .form { display: flex; flex-direction: column; gap: 12px; }
  label { display: flex; flex-direction: column; gap: 6px; font-size: 13px; font-weight: 600; color: var(--muted); }
  input { background: var(--surface-2); color: var(--text); border: 1px solid #2a2a2e; border-radius: 10px; padding: 11px; font-size: 16px; }
  .rows { display: flex; flex-direction: column; gap: 8px; }
  .prow { padding: 10px 12px; display: flex; align-items: center; justify-content: space-between; }
  .pn { font-weight: 700; font-size: 14px; }
  .pm { font-size: 12px; }
  .rm { background: var(--surface-2); border: 1px solid #2a2a2e; color: var(--muted); border-radius: 8px; width: 30px; height: 30px; }
  .total { font-size: 13px; font-weight: 600; }
  .actions { display: flex; gap: 10px; }
  .actions .btn-primary { flex: 1; }
</style>
```

- [ ] **Step 2: Replace `src/lib/components/PlansSegment.svelte`**

```svelte
<script lang="ts">
  import { plans, addPlan, updatePlan, deletePlan } from '$lib/stores/plans';
  import { foods, findFood } from '$lib/stores/foods';
  import { applyPlanToDay, todayKey } from '$lib/stores/log';
  import { scaleMacros, sumMacros } from '$lib/utils/nutrition';
  import type { DietPlan } from '$lib/types';
  import Modal from './Modal.svelte';
  import Fab from './Fab.svelte';
  import PlanForm from './PlanForm.svelte';

  let creating = $state(false);
  let editing = $state<DietPlan | null>(null);
  let applied = $state<string | null>(null);

  function planTotal(plan: DietPlan) {
    const macros = plan.items
      .map((it) => { const f = findFood($foods, it.foodId); return f ? scaleMacros(f.perServing, it.quantity) : null; })
      .filter((m) => m !== null) as any;
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
```

- [ ] **Step 3: Typecheck**

Run: `npm run check`
Expected: no errors.

- [ ] **Step 4: Manual verification**

Run: `npm run dev` → Food → Plans.
- FAB → New plan → name it, add 2–3 foods (each via picker + quantity), see running total, Save → plan card appears with item count + kcal.
- "Apply to today" → toast shows; switch to Today → those items are in the log and totals updated.
- Edit a plan (rename, remove an item, Save); delete a plan.
Expected: all above true, persists across reload.

- [ ] **Step 5: Commit**

```bash
git add src/lib/components/PlanForm.svelte src/lib/components/PlansSegment.svelte
git commit -m "feat: add diet Plans segment with build, edit, and apply-to-today"
```

---

### Task 10: PWA icons, service worker, final polish

**Files:**
- Create: `src/service-worker.ts`
- Create: `static/icon-192.png`, `static/icon-512.png` (generated)
- Modify: `static/manifest.webmanifest` (reference real icons)
- Modify: `src/app.html` (apple-touch-icon)

**Interfaces:**
- Consumes: SvelteKit `$service-worker` module (`build`, `files`, `version`).
- Produces: installable, offline-capable PWA.

- [ ] **Step 1: Generate app icons (red "L" on dark)**

Run this Node script (writes two PNGs via a minimal canvas-free approach using `sharp` if present, else a solid-color fallback). Use the fallback that needs no deps:
```bash
node --input-type=module -e '
import { writeFileSync } from "node:fs";
// 1x1 red PNG scaled by the browser is ugly; instead emit a simple SVG-based data pipeline is not available.
// Minimal valid solid PNG generator (single color) for 512 and 192.
function solidPng(size, [r,g,b]) {
  const zlib = await import("node:zlib");
  const w = size, h = size;
  const row = Buffer.alloc(1 + w*3);
  for (let x=0;x<w;x++){ row[1+x*3]=r; row[2+x*3]=g; row[3+x*3]=b; }
  const raw = Buffer.concat(Array.from({length:h}, () => row));
  const idat = zlib.deflateSync(raw);
  const crc = (buf) => { let c=~0; for (const b of buf){ c^=b; for(let k=0;k<8;k++) c = (c>>>1) ^ (0xEDB88320 & -(c&1)); } return (~c)>>>0; };
  const chunk = (type, data) => { const t=Buffer.from(type); const len=Buffer.alloc(4); len.writeUInt32BE(data.length); const cr=Buffer.alloc(4); cr.writeUInt32BE(crc(Buffer.concat([t,data]))); return Buffer.concat([len,t,data,cr]); };
  const sig = Buffer.from([137,80,78,71,13,10,26,10]);
  const ihdr = Buffer.alloc(13); ihdr.writeUInt32BE(w,0); ihdr.writeUInt32BE(h,4); ihdr[8]=8; ihdr[9]=2;
  return Buffer.concat([sig, chunk("IHDR",ihdr), chunk("IDAT",idat), chunk("IEND",Buffer.alloc(0))]);
}
const red = [224,30,43];
writeFileSync("static/icon-512.png", await solidPng(512, red));
writeFileSync("static/icon-192.png", await solidPng(192, red));
writeFileSync("static/favicon.png", await solidPng(192, red));
console.log("icons written");
'
```
Expected: prints "icons written"; three PNGs exist under `static/`.

> If `sharp` or ImageMagick is available and a nicer branded icon is desired, replace these solids later — functionally the solids satisfy PWA install requirements.

- [ ] **Step 2: Update `static/manifest.webmanifest`**

```json
{
  "name": "LuxiFit",
  "short_name": "LuxiFit",
  "start_url": "/food",
  "scope": "/",
  "display": "standalone",
  "background_color": "#0B0B0C",
  "theme_color": "#0B0B0C",
  "icons": [
    { "src": "/icon-192.png", "sizes": "192x192", "type": "image/png", "purpose": "any" },
    { "src": "/icon-512.png", "sizes": "512x512", "type": "image/png", "purpose": "any maskable" }
  ]
}
```

- [ ] **Step 3: Add apple-touch-icon to `src/app.html`**

Add inside `<head>`, after the manifest link:
```html
    <link rel="apple-touch-icon" href="%sveltekit.assets%/icon-192.png" />
```

- [ ] **Step 4: Create `src/service-worker.ts` (offline cache)**

```ts
/// <reference types="@sveltejs/kit" />
import { build, files, version } from '$service-worker';

const CACHE = `luxifit-${version}`;
const ASSETS = [...build, ...files];

self.addEventListener('install', (event) => {
  (event as ExtendableEvent).waitUntil(
    caches.open(CACHE).then((cache) => cache.addAll(ASSETS))
  );
});

self.addEventListener('activate', (event) => {
  (event as ExtendableEvent).waitUntil(
    caches.keys().then((keys) =>
      Promise.all(keys.filter((k) => k !== CACHE).map((k) => caches.delete(k)))
    )
  );
});

self.addEventListener('fetch', (event) => {
  const e = event as FetchEvent;
  if (e.request.method !== 'GET') return;
  e.respondWith(
    caches.match(e.request).then((cached) => cached ?? fetch(e.request))
  );
});

export {};
```

- [ ] **Step 5: Typecheck and build**

Run:
```bash
npm run check
npm run build
```
Expected: no errors; `build/` produced. (Service worker type warnings about `self` can be suppressed if needed by adding `declare const self: ServiceWorkerGlobalScope;` at the top of the file — add it only if `npm run check` complains.)

- [ ] **Step 6: Manual PWA verification**

Run: `npm run preview`. In Chrome DevTools → Application:
- Manifest is detected (name LuxiFit, icons present, no errors).
- Service worker registers and activates.
- Offline toggle: reload still serves the app shell.
Expected: all above true; install prompt/"Add to Home Screen" available.

- [ ] **Step 7: Full regression + commit**

Run: `npm test`
Expected: all suites PASS.
```bash
git add src/service-worker.ts static/manifest.webmanifest src/app.html static/icon-192.png static/icon-512.png static/favicon.png
git commit -m "feat: add PWA icons, manifest, and offline service worker"
```

---

## Self-Review

**Spec coverage:**
- Predefined foods + quantity → auto macros/calories: Tasks 4, 8 (FoodPicker, TodaySegment). ✓
- 4 macros (Protein/Carbs/Fiber/Fats) + calories + vitamins field: Task 2 types, Task 3 math, Tasks 7–8 UI. ✓
- Profile setup (target/current weight, height, age) → BMI + status + target BMI: Tasks 3, 7. ✓
- Add new food / edit default macros: Task 8 (FoodForm, FoodsSegment). ✓
- Diet plan repeatable daily: Task 9 (applyPlanToDay). ✓
- Junk options: seed `isJunk` (Task 4) + junk filter + form toggle (Task 8). ✓
- Svelte webapp, black/white/red, "Material grid": Task 1 theme + card grid throughout. ✓
- Bottom nav Food/Progress/Workout/Anatomy, others placeholder: Task 1. ✓
- Food only for now: Progress/Workout/Anatomy are placeholders. ✓

**Placeholder scan:** No "TBD"/"add error handling" placeholders; the one intentional stub (PlansSegment in Task 8) is created explicitly in Task 8 Step 9 and replaced in Task 9.

**Type consistency:** `FoodDraft = Omit<Food,'id'|'isDefault'>` used consistently in `addFood`/`FoodForm`. `logItemFromFood`, `applyPlanToDay`, `findFood`, `getDay`, `todayKey`/`dateKey` names match between `stores/log.ts` (Task 5) and consumers (Tasks 8–9). `saveProfile` sets `onboarded: true` (Task 5) which the onboarding gate reads (Task 7). Nutrition signatures in Task 3 match calls in Tasks 7–9.

**Note on calories editing:** `FoodForm` uses `calOverride` (nullable) with `autoCal` fallback, satisfying "calories auto-derived but editable."
