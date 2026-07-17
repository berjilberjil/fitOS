# fitOS

A fitness + nutrition tracker for a Tamil-Nadu audience. **One product, two
front-ends, one backend.** The web app *is* the backend; the native iOS app is a
second UI on top of the exact same API and data.

- **Live:** https://fit.berjiljacob.com (SvelteKit web app + API, on Netlify)
- **iOS:** native SwiftUI client that talks to that same backend — same accounts,
  same data, nothing duplicated.

```
apps/
  web/    SvelteKit web app + THE API/server (Supabase Postgres).
          This is the backend for BOTH front-ends. Deploys to Netlify.
  ios/    Native SwiftUI app. Talks to apps/web's /api/* — same cookie session,
          same data. Only the UI is native; no backend is re-implemented.
```

> The old Tauri webview shell lives at `apps/web/src-tauri` and is **dead** —
> fully replaced by the native app in `apps/ios`. Don't build on it.

---

## The one idea that makes this whole thing work

There is **no per-feature backend.** The server is basically:

1. **Auth** — username/password → an httpOnly cookie session.
2. **A per-user key→JSON store** — `GET /api/state`, `PUT /api/state/{key}`.
3. **Read-only catalogs** — `/api/catalog`, `/api/anatomy` (static seed data).
4. **One AI helper** — `/api/voice/parse` (spoken meal → structured log).

All the *app data* — your profile, food log, workout plan, weight history, custom
foods — is just JSON documents stored under string keys like `luxifit.profile`,
`luxifit.log`, `luxifit.workoutplan`. The web client and the iOS client both read
and write the **same keys**, so they stay in sync automatically. Add a feature by
adding a new key and a UI for it — the server usually doesn't change at all.

```
   Web (Svelte stores)                iOS (AppState)
        │                                  │
        │  synced('luxifit.log', …)        │  @Published log
        │  debounced PUT on change         │  debounced PUT on change
        ▼                                  ▼
        └──────────►  PUT /api/state/{key}  ◄──────────┘
                              │
                              ▼
                 Postgres  app_state(user_id, key, jsonb)
                              │
        ┌──────────◄  GET /api/state  (hydrate on login)  ◄────────┐
        ▼                                                          ▼
   Web hydrates all stores                     iOS hydrates AppState
```

Everything below is detail on top of that idea.

---

## Tech stack

### Backend + web (`apps/web`) — the source of truth

| Concern        | Choice                                          |
|----------------|-------------------------------------------------|
| Framework      | **SvelteKit 2** + **Svelte 5** (runes: `$props`, `$state`) |
| Language       | **TypeScript** (strict)                         |
| Build/dev      | **Vite 5**                                       |
| Rendering      | **Client-side SPA** — `ssr = false`, `prerender = false` (see `src/routes/+layout.ts`). SvelteKit is used for routing + the `/api` server endpoints, not SSR pages. |
| Adapter        | `adapter-netlify` on Netlify, `adapter-node` locally (auto-switch in `svelte.config.js` via the `NETLIFY` env var) |
| Database       | **Postgres** (Supabase), via **`postgres`** (postgres.js). Single shared pool in `src/lib/server/db.ts`; `prepare:false` for pooler/serverless compatibility. |
| Auth           | Hand-rolled — `scrypt` password hash + opaque session token in a `sessions` table + httpOnly cookie. No third-party auth lib. |
| AI             | **Vercel AI SDK** (`ai`) + **`@ai-sdk/google`** (Gemini) for voice parsing, with **`zod`** schemas for structured output. |
| Object storage | **Cloudflare R2** (S3-compatible) for progress photo **bytes**. Metadata stays in Postgres `app_state`. |
| Icons          | **`@iconify/svelte`**                            |
| PWA            | Custom service worker (`src/service-worker.ts`) — precache the app shell, never cache `/api`. |
| Tests          | **Vitest** (jsdom) — `*.test.ts` next to the code. |

### iOS (`apps/ios`) — a native client, no backend

| Concern        | Choice                                          |
|----------------|-------------------------------------------------|
| UI             | **SwiftUI** (Swift 5.9, **iOS 16** deployment target — Swift Charts needs 16) |
| Project gen    | **XcodeGen** — `project.yml` is the source of truth; `.xcodeproj` is generated and git-ignored |
| Networking     | `URLSession` + shared `HTTPCookieStorage` → reuses the server's `luxifit_session` cookie (`Support/APIClient.swift`, base URL `https://fit.berjiljacob.com`) |
| State          | One `AppState: ObservableObject` that mirrors the web's synced stores |
| Charts         | Swift Charts (weight trend) |
| Native wins    | **HealthKit** (weight/steps), **Face ID** lock, **Speech** framework (on-device transcription), **haptics**, local **notifications**, **progress photos** (R2) |
| Device install | Free Apple ID (~7-day cert) + optional **daily auto rebuild** via LaunchAgent (`apps/ios/scripts/`) |

There is **no Swift server, no Core Data, no local DB.** The phone is a thin,
beautiful client over the same HTTP API the browser uses.

---

## The API (all under `apps/web/src/routes/api`)

Everything is a SvelteKit `+server.ts` endpoint. Sessions are resolved once per
request in `src/hooks.server.ts` → `event.locals.user`.

### Auth
| Method & path              | Body / notes | Returns |
|----------------------------|--------------|---------|
| `POST /api/auth/register`  | `{username, password}` (username ≥3, password ≥4) | sets cookie, `{id, username}` |
| `POST /api/auth/login`     | `{username, password}` | sets cookie, `{id, username}` |
| `POST /api/auth/logout`    | — | clears the session |
| `GET  /api/me`             | — | `{id, username}` or 401 |

Cookie: `luxifit_session`, httpOnly, `sameSite:lax`, 30-day, **`secure:false`**
on purpose (so it also works over plain HTTP on the LAN for friends). Passwords
hashed with `scrypt` (`src/lib/server/auth.ts`).

### Per-user state (the KV store — where almost all data lives)
| Method & path            | Purpose |
|--------------------------|---------|
| `GET /api/state`         | all of the user's keys as `{ key: value }` — used to hydrate on login |
| `PUT /api/state/{key}`   | upsert one key's JSON document (`on conflict … do update`) |

Stored in the `app_state(user_id, key, value jsonb, updated_at)` table — one row
per (user, key). The server never interprets the JSON; the clients own the shape.

**The keys in use today** (defined by the client stores):

| Key                   | Shape (`apps/web/src/lib/types.ts`)     | What it is |
|-----------------------|-----------------------------------------|------------|
| `luxifit.profile`     | `Profile`                               | age, sex, height, weights, activity, onboarded |
| `luxifit.foods`       | `Food[]`                                | full food list = seed + user's custom/edited |
| `luxifit.exercises`   | `Exercise[]`                            | full exercise list = seed + custom |
| `luxifit.log`         | `Record<dateStr, DayLog>`               | what was eaten, per day |
| `luxifit.weekplan`    | `WeekPlan`                              | repeatable weekly meal routine |
| `luxifit.workoutplan` | `WorkoutWeekPlan`                       | repeatable weekly workout routine |
| `luxifit.workoutlog`  | `Record<dateStr, WorkoutDayLog>`        | what was actually trained, per day (carries working weight) |
| `luxifit.weightlog`   | `Record<dateStr, number>`               | body-weight history |
| `luxifit.progressphotos` | `ProgressPhoto[]` (metadata only)    | progress shots — **bytes in R2**, not base64 in Postgres |
| `luxifit.settings`    | `Settings`                              | misc client settings |

### Media (Cloudflare R2 — progress photos)
| Method & path              | Purpose |
|----------------------------|---------|
| `POST /api/media/upload`   | Auth required. Body `{ jpegBase64, id?, date?, note? }` → puts JPEG in R2, returns `{ id, date, key, url, note, createdAt }` (no bytes). |
| `GET  /api/media?key=…`    | Auth required. Streams JPEG if `key` is owned by the logged-in user (`progress/{userId}/…`). |
| `DELETE /api/media`        | Auth required. Body `{ key }` — deletes the R2 object (client still removes the row from `luxifit.progressphotos`). |

Object key shape: `progress/{userId}/{photoId}.jpg`. Bucket/env: `R2_BUCKET`, `R2_ENDPOINT`, `R2_ACCESS_KEY_ID`, `R2_SECRET_ACCESS_KEY` (see `apps/web/.env.example`). Never commit secrets.

### Read-only catalogs (public, cached at the edge for 1h)
| Method & path      | Returns |
|--------------------|---------|
| `GET /api/catalog` | `{ foods, exercises, media }` — the seed data + exercise demo media. One source of truth for both clients. |
| `GET /api/anatomy` | `{ front, back, groups, activation }` — SVG body-map paths + muscle groups + per-group activation rankings. |

These re-serve the same `src/lib/data/*` files the web bundle imports, so the
native app never hard-codes catalog data.

### AI
| Method & path            | Notes |
|--------------------------|-------|
| `POST /api/voice/parse`  | `{transcript, foods, plannedFoodIds}` → Gemini via AI SDK `generateObject` (+ Zod schema) → `{meal, items[]}`. Needs `GEMINI_API_KEY`; returns 503 if unset. Speech-to-text happens **on the client** (Web Speech API / iOS Speech framework); this endpoint only does the *meaning* → structured log. |

---

## Data model (Postgres)

Three tables — see `apps/web/db/schema.sql`:

```sql
users     (id, username unique, password_hash, created_at)
sessions  (token pk, user_id → users, expires_at)
app_state (user_id, key, value jsonb, updated_at,  primary key (user_id, key))
```

That's it. No per-feature tables — features are JSON docs in `app_state`.

---

## Repo layout

```
apps/web/
  db/schema.sql                 Postgres schema (run once on a fresh DB)
  svelte.config.js              adapter auto-switch (Netlify vs node)
  src/
    hooks.server.ts             cookie → locals.user on every request
    app.css                     design tokens (dark + fitOS red) — mirrored into iOS Theme.swift
    routes/
      +layout.svelte / .ts      SPA shell, auth gate, nav
      food|progress|workout|anatomy/+page.svelte   the four tabs
      api/…                     all endpoints described above
    lib/
      server/{db,auth}.ts       Postgres pool + auth (server-only)
      stores/                   Svelte stores; each `persisted('luxifit.*', …)` key
        sync.ts                 THE sync engine (hydrate + debounced push)
      data/                     seed foods/exercises, anatomy paths, media (static)
      components/               all UI
      utils/nutrition.ts        Mifflin-St Jeor TDEE + macro targets
      types.ts                  the shared data shapes (mirrored into iOS Models.swift)

apps/ios/
  project.yml                   XcodeGen manifest (targets, capabilities, Info.plist keys)
  fitOS.entitlements            HealthKit
  FRIEND_SETUP.md               Free Apple ID + daily auto reinstall (for you or a friend)
  scripts/
    setup-auto-install.sh       install / uninstall / status / run the daily job
    auto-install-device.sh      git pull (best-effort) → xcodebuild → install on phone
    com.berjil.fitos.autoinstall.plist   LaunchAgent template (10 PM)
  Sources/fitOS/
    fitOSApp.swift              @main, injects AppState
    Support/                    APIClient, AppState, Models, Nutrition, Theme,
                                Health/Voice/Biometric/Haptics/Notifications, SVGPath, R2 media
    Views/                      SwiftUI screens (one per tab + sheets)
  Resources/Assets.xcassets     AccentColor + AppIcon
```

---

## Daily auto rebuild (iOS on a free Apple account)

Free personal-team installs expire about **every 7 days**. fitOS can reinstall
itself from **your Mac** every night so the app keeps working — and picks up
whatever is on **GitHub `main`**.

Full friend walkthrough: **[`apps/ios/FRIEND_SETUP.md`](apps/ios/FRIEND_SETUP.md)**.

### What the job does (every day at **10:00 PM** local)

1. **`git pull --ff-only`** in the clone (best-effort).
2. If pull **fails** (no network, auth, conflicts) → **still rebuilds from the local tree** and installs. Pull never blocks install.
3. `xcodebuild` Debug → `devicectl` install → launch on the paired iPhone.
4. Skips quietly if no phone is paired/connected, or if a successful run was &lt;20h ago (use `--force` to override).

### One-time setup (each Mac / each person)

```bash
# 1) Clone + first Xcode Run on a real iPhone (signing Team once)
cd apps/ios && xcodegen generate && open fitOS.xcodeproj   # ⌘R on device

# 2) From repo root — enable the LaunchAgent on THIS Mac only
bash apps/ios/scripts/setup-auto-install.sh install
```

### Day-to-day commands

```bash
bash apps/ios/scripts/setup-auto-install.sh status   # last success, device, agent
bash apps/ios/scripts/setup-auto-install.sh run      # rebuild + install now (--force)
bash apps/ios/scripts/setup-auto-install.sh uninstall
open ~/Library/Logs/fitOS/auto-install.log           # full log
```

| Person | Auto job |
|--------|----------|
| **You** | Your Mac @ 10 PM → your iPhone (after `install` once) |
| **Friend** | **Their** Mac after **they** clone, Xcode Run once, and run `setup-auto-install.sh install` |

Cloning alone does **not** enable the job. Data (food/weight/workouts/photos metadata) lives on the server — reinstall does not wipe the account.

Optional: `FITOS_SKIP_GIT_PULL=1` to rebuild without pulling; `FITOS_BUNDLE_ID=…` if the friend changed the bundle id.

---

## Local development

### Prereqs
- **Node 20** (Netlify builds on 20)
- A Postgres URL (Supabase or local). Set it in `apps/web/.env`:
  ```
  DATABASE_URL=postgres://…            # required
  GEMINI_API_KEY=…                     # optional — only voice parsing needs it
  GEMINI_MODEL=gemini-2.5-flash        # optional (default shown)
  # Progress photos (Cloudflare R2) — required for new photo uploads
  R2_ACCOUNT_ID=…
  R2_ACCESS_KEY_ID=…
  R2_SECRET_ACCESS_KEY=…
  R2_BUCKET=fitos-media
  R2_ENDPOINT=https://<accountid>.r2.cloudflarestorage.com
  ```
  Copy from `apps/web/.env.example`. Never commit real secrets.
- On a fresh database, apply the schema once: `psql "$DATABASE_URL" -f apps/web/db/schema.sql`
- For iOS: **Xcode 15+** and **XcodeGen** (`brew install xcodegen`).

### Commands (from repo root)
```bash
npm run web          # dev server for the web app + API  (vite dev)
npm run web:build    # production build (exactly what Netlify runs)
npm run web:check    # svelte-check / typecheck
npm --prefix apps/web run test   # vitest

npm run ios:gen      # regenerate apps/ios/fitOS.xcodeproj from project.yml
npm run ios:open     # open it in Xcode  (then ⌘R on a device/simulator)

# Daily free-signing reinstall (see section above)
bash apps/ios/scripts/setup-auto-install.sh install|run|status|uninstall
```

### Deploy
Netlify builds from `apps/web` (set via `base` in `netlify.toml`), runs
`npm run build`, publishes `build/`. Set `DATABASE_URL` / `GEMINI_API_KEY` /
`GEMINI_MODEL` and the `R2_*` vars in the Netlify site env. `apps/ios` is
ignored by the web build — ship the native app via Xcode or the auto-install job.

---

## How to make changes — READ THIS BEFORE ADDING A FEATURE

The whole architecture is designed so that **new features are cheap and don't
touch the server.** Match the existing pattern instead of inventing a new one.

### The golden rules
1. **The backend lives in `apps/web`. Never re-implement it in Swift.** The iOS
   app only calls `/api/*`.
2. **New app data = a new `luxifit.*` key, not a new table or endpoint.** The
   generic `/api/state/{key}` already stores any JSON. Adding a Postgres column or
   a bespoke endpoint for feature data is almost always the wrong move.
3. **Static/reference data (foods, exercises, anatomy) is edited in
   `apps/web/src/lib/data/*`** and served through `/api/catalog` / `/api/anatomy`.
   Both clients pick it up on next hydrate — never hard-code it in the iOS app.
4. **Types are hand-mirrored** between `apps/web/src/lib/types.ts` and
   `apps/ios/.../Support/Models.swift`. Change one → change the other in the same
   change. Same for nutrition math (`utils/nutrition.ts` ↔ `Support/Nutrition.swift`)
   and the theme (`app.css` ↔ `Support/Theme.swift`).

### Recipe A — add a new piece of synced user data
1. Define/extend the type in `apps/web/src/lib/types.ts`.
2. Create a store in `apps/web/src/lib/stores/` using
   `persisted('luxifit.<newkey>', <default>)` (from `sync.ts`). Registering the key
   is all it takes — hydrate + debounced push are automatic.
3. Build the Svelte UI in `lib/components/` and wire it into the relevant
   `routes/*/+page.svelte`.
4. Mirror the Swift type in `Models.swift`, add an `@Published` field to
   `AppState`, load it in `hydrate()`, and `PUT /api/state/luxifit.<newkey>` on
   change (copy an existing field's pattern exactly).
5. Build the SwiftUI screen. **No server change needed.**

### Recipe B — add/adjust catalog data (a food, an exercise, muscle data)
- Edit the seed file in `apps/web/src/lib/data/` (`seed-foods.ts`,
  `seed-exercises.ts`, `exercise-media.ts`, `anatomy.ts`, `body-paths.ts`, …).
- It flows to the web bundle directly and to iOS via `/api/catalog` / `/api/anatomy`.
- Note: once a user edits their list, `luxifit.foods` / `luxifit.exercises` holds
  the **full** list; the client prefers the user's list over the catalog to avoid
  duplicates.

### Recipe C — a genuinely new server capability (like voice was)
- Only then add a new `src/routes/api/<thing>/+server.ts`. Gate it on
  `locals.user`, validate input with Zod, keep secrets in `env`.

### iOS mechanics
- After adding/removing Swift files, **regenerate the project**: `npm run ios:gen`
  (XcodeGen builds the target from file lists in `project.yml`).
- New capabilities/permissions go in `project.yml` (Info.plist keys +
  `fitOS.entitlements`), then regenerate.
- **Building for the device is the compile check** — no separate Swift test suite.
- iOS ships in **waves**: build → install to device → verify → next wave.

### Conventions
- Svelte 5 runes (`$props`, `$state`, `$derived`) — not the old `export let`.
- Server-only code (DB, secrets) stays under `lib/server/**` and `+server.ts`;
  never import it into client components.
- Tests: Vitest, `*.test.ts` beside the unit (see `nutrition.test.ts`,
  `seed-foods.test.ts`, `stores.test.ts`). Run `npm --prefix apps/web run test`.
- Money-where-your-mouth-is check before claiming done: `npm run web:check` for
  the web, a device build for iOS.

---

## Why a plain monorepo (not Turborepo)

Turbo orchestrates JS/TS build graphs — it can't build an Xcode target, so it adds
config for no gain here. `apps/web` is self-contained (own `package.json` +
lockfile, built by Vite/Netlify); `apps/ios` is built by Xcode. Two build systems,
one shared HTTP contract — a plain monorepo is the honest shape.

See `apps/ios/README.md` for iOS-specific build/run detail.
