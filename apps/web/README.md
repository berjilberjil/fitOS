# fitOS

A personal fitness operating system — food logging (with AI voice), workout planning with progressive overload, an interactive anatomy map, and a progress dashboard.

## Features

- **Food** — Tamil-Nadu food database with real photos, macro tracking, meal-based daily logging, junk options, and **AI voice logging** (say *"3 chapati and 100ml milk for breakfast"* → it's logged).
- **Workout** — 90+ exercises across chest / back / shoulders / arms / legs / core / cardio / boxing, animated demos, weekly plans, rest days, and **progressive-overload** weight tracking (last vs this session).
- **Anatomy** — an accurate body map; tap any muscle to see the exercises that build it, **ranked by activation %**.
- **Progress** — weight trend, BMI, estimated body-fat %, a **six-pack timeline**, and smart cut / bulk / recomp suggestions.
- **Accounts** — multi-user, data synced to a Postgres backend.

## Stack

SvelteKit 2 · Svelte 5 (runes) · Postgres · Node (`adapter-node`) · Google Gemini (voice parsing, server-side) · Iconify.

## Run

```bash
npm install
# create .env with:
#   DATABASE_URL=postgresql://<user>@localhost:5432/fitos
#   GEMINI_API_KEY=...            (for voice logging)
#   GEMINI_MODEL=gemini-3.1-flash-lite
psql -d fitos -f db/schema.sql   # once
npm run dev                        # or: npm run build && node build
```
