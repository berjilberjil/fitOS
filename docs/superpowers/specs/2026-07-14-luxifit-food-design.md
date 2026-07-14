# LuxiFit — Food Feature Design

**Date:** 2026-07-14
**Status:** Approved (design), pending implementation plan
**Scope:** Build the **Food** feature end-to-end. Progress, Workout, and Anatomy tabs are styled placeholders only.

---

## 1. Purpose

A mobile-first fitness web app for gym-goers to track food intake and macros. The user picks from a database of predefined foods (defaulting to Tamil-Nadu / Chennai fitness foods), sets a quantity, and the app computes calories + macros automatically. The user can add/edit/delete foods (including defaults), build repeatable diet plans, and set up a profile that computes BMI and status against a target.

This spec covers the **Food** feature only. The other three tabs exist in the shell as placeholders.

---

## 2. Stack & Architecture

- **Framework:** SvelteKit with `@sveltejs/adapter-static` (SPA/PWA, no server).
- **Language:** TypeScript.
- **Build:** Vite.
- **PWA:** web manifest + service worker → installable to phone home screen, works offline.
- **Persistence:** `localStorage`, wrapped in a typed persisted-store helper. Data volume is tiny (dozens of foods, a few plans, one small entry per day). Migration to IndexedDB is possible later without touching consumers.
- **Testing:** Vitest for pure nutrition math and store logic.

### Design language (black / white / red, "Material grid")

- Canvas near-black `#0B0B0C`; surfaces slightly lifted `#141416`; text white `#F5F5F5` / muted `#9A9A9E`.
- One red accent `#E01E2B` (active nav, FAB, progress fill, primary buttons).
- Card-based grid surfaces, ~16px radius, soft elevation shadows.
- Material-style **bottom navigation** and a red circular **FAB** for adding.
- Mobile-first; on wider screens the app sits in a centered column (max-width ~480px).

---

## 3. Navigation

Persistent **bottom nav** with 4 tabs, icon + label, red highlight on the active tab:

| Tab | State |
|-----|-------|
| **Food** | Fully built (this spec) |
| **Progress** | Placeholder screen ("Coming soon") |
| **Workout** | Placeholder screen ("Coming soon") |
| **Anatomy** | Placeholder screen ("Coming soon") |

The Food tab contains its own **segmented control** (Today · Foods · Plans) so the bottom nav stays exactly 4 items.

---

## 4. Food Tab — the three segments

### 4.1 Today (default segment)

- Date header (defaults to today; can page back/forward across days).
- **Running totals** for **Calories, Protein, Carbs, Fiber, Fats**, shown as rings/bars against the user's goals (e.g. "1450 / 2000 kcal").
- List of logged items for the day (food name, quantity, its macro contribution), each removable.
- Red **FAB** → opens the **Food Picker** (search/select a food + enter quantity → adds to today's log).

### 4.2 Foods (the food database)

- Searchable **card grid** of all foods (default + user-added).
- Category filter chips, including a **Junk** filter.
- **Add new food** button → Food Form.
- Any food card → view / **edit** / **delete**, including default foods.
- Seeded with ~50 Tamil-Nadu fitness foods on first run (see §7).

### 4.3 Plans (repeatable diets)

- List of saved **diet plans** (e.g. "Cut Day", "Rest Day").
- Create/edit a plan by picking foods + quantities.
- **"Apply to today"** copies the plan's items into today's log so a diet can be repeated daily.
- Edit / delete plans.

---

## 5. Profile, BMI & Goals

**First run:** onboarding collects `age`, `sex`, `heightCm`, `currentWeightKg`, `targetWeightKg`. Editable later via a profile icon in the Food header.

- **BMI** = `weightKg / (heightM)^2`.
- **Status bands:** `<18.5` underweight · `18.5–24.9` normal · `25–29.9` overweight · `≥30` obese.
- Shows current BMI + status, **target BMI** (derived from target weight + height), and the delta to target.
- **Daily calorie goal:** Mifflin-St Jeor BMR × activity factor.
  - Male BMR = `10·kg + 6.25·cm − 5·age + 5`; Female = `10·kg + 6.25·cm − 5·age − 161`.
  - Activity factor selectable (sedentary 1.2 … very active 1.725), default light 1.375.
- **Daily protein goal:** `~1.8 g/kg` of current weight.
- These goals drive the Today rings/bars.

---

## 6. Data Model

Four persisted stores, all in `localStorage`.

```ts
type Sex = 'male' | 'female';
type Category = 'protein' | 'carb' | 'veg' | 'dairy' | 'fruit' | 'drink' | 'junk' | 'other';

interface Macros {
  calories: number; // kcal
  protein: number;  // g
  carbs: number;    // g
  fiber: number;    // g
  fats: number;     // g
}

interface Food {
  id: string;
  name: string;
  category: Category;
  servingLabel: string;   // e.g. "1 chapati", "1 cup", "100 g"
  perServing: Macros;     // macros for ONE serving
  vitamins?: string;      // informational tag/note, e.g. "Iron, B12" — shown, NOT summed
  isJunk: boolean;
  isDefault: boolean;     // seeded vs user-added (both editable/deletable)
}

interface PlanItem { foodId: string; quantity: number; }
interface DietPlan { id: string; name: string; items: PlanItem[]; }

// Log snapshots macros at log time so later food edits don't rewrite history.
interface LogItem { foodId: string; name: string; quantity: number; macros: Macros; }
interface DayLog { date: string; /* YYYY-MM-DD */ items: LogItem[]; }

interface Profile {
  name?: string;
  age: number;
  sex: Sex;
  heightCm: number;
  currentWeightKg: number;
  targetWeightKg: number;
  activity: number;       // Mifflin activity factor
  onboarded: boolean;
}
```

**Quantity** is a serving count (supports decimals: 0.5, 3, etc.). A food's contribution = `perServing × quantity`.

---

## 7. Default seed foods (~50, Tamil-Nadu fitness angle)

A curated seed list with realistic per-serving macros, spanning:

- **Protein:** boiled egg, egg whites, chicken breast, fish (e.g. sardine/seer), paneer, boiled channa, moong sprouts, soya chunks.
- **Carbs / staples:** idli, dosa, chapati, plain white rice (1 cup), brown rice, curd rice, ragi kali/ball, oats, upma, poha, pongal.
- **Dals / gravies:** sambar, rasam, dal (thuvaram paruppu), kootu.
- **Dairy:** curd, milk, buttermilk.
- **Fruit / snacks:** banana, groundnut/peanuts, dates.
- **Drinks:** black coffee, tea with sugar, tender coconut.
- **Junk (isJunk: true):** parotta, chicken biryani, medu vada, bajji, samosa, sugar sweet (e.g. jangiri), soft drink, bakery bun.

Exact macro values are curated during implementation; the list above defines coverage.

---

## 8. Component / File Structure

```
src/
  app.html
  app.css                     // theme tokens, resets
  lib/
    types.ts
    data/seed-foods.ts         // the ~50 defaults
    utils/
      persist.ts               // localStorage-backed persisted store
      nutrition.ts             // bmi, bmr/tdee, protein goal, scaleMacros, sumMacros
      id.ts                    // id generation
    stores/
      profile.ts
      foods.ts                 // seeded on first init
      plans.ts
      log.ts                   // keyed by date
    components/
      BottomNav.svelte
      SegmentedControl.svelte
      MacroRing.svelte
      MacroBar.svelte
      FoodCard.svelte
      FoodPicker.svelte        // modal: choose food + quantity
      FoodForm.svelte          // add/edit food
      PlanCard.svelte
      Fab.svelte
      Modal.svelte
  routes/
    +layout.svelte             // app shell: centered column + bottom nav
    +page.ts                   // redirect "/" -> "/food"
    food/+page.svelte          // segmented Today / Foods / Plans + onboarding gate
    progress/+page.svelte      // placeholder
    workout/+page.svelte       // placeholder
    anatomy/+page.svelte       // placeholder
static/
  manifest.webmanifest, icons, service worker assets
```

---

## 9. Testing

TDD for the pure functions in `utils/nutrition.ts`:

- `bmi`, `bmiStatus`, `targetBmi`
- `bmr` (Mifflin-St Jeor, both sexes), `tdee`, `proteinGoal`
- `scaleMacros(perServing, quantity)`, `sumMacros(items)`, `caloriesFromMacros` (Atwater with fiber, per §10.4)

Store-init logic (seed on first run, persistence round-trip) gets lighter coverage. Components are exercised manually.

---

## 10. Decisions (locked)

1. **Vitamins** are an optional informational field on a food, shown but not numerically summed. The 4 macros + calories are the tracked numbers.
2. App computes a **calorie goal** (Mifflin-St Jeor + activity) and **protein goal** (~1.8 g/kg) that drive Today's rings.
3. **Log snapshots macros** at log time — editing a food later does not rewrite past days.
4. **Calories** default-derive from macros but are editable per food to match labels. `carbs` is **total** carbohydrate (fiber included), so to avoid double-counting: `calories = protein·4 + fat·9 + (carbs − fiber)·4 + fiber·2`. If `fiber > carbs`, clamp the digestible term at 0.
5. Storage is **on-device localStorage**; stack is **SvelteKit static PWA**.

---

## 11. Non-Goals (YAGNI)

- No accounts, backend, or cloud sync.
- No barcode scanning or external nutrition API.
- No charts yet — Progress is a placeholder.
- No Workout or Anatomy logic.
