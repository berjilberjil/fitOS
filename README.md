# fitOS — monorepo

One product, two front-ends on a shared backend.

```
apps/
  web/    SvelteKit web app + the API/server (Supabase Postgres).
          This is the backend for BOTH front-ends. Deploys to Netlify
          at fit.berjiljacob.com.
  ios/    Native SwiftUI app. Talks to apps/web's /api/* — same accounts,
          same data. No backend duplicated; only the UI is native.
```

The old Tauri iOS shell lives at `apps/web/src-tauri` and is being replaced by the
native app in `apps/ios`.

## Common commands (from repo root)

```bash
npm run web          # dev server for the web app + API
npm run web:build    # production build (what Netlify runs)
npm run ios:gen      # generate the Xcode project (needs xcodegen)
npm run ios:open     # open it in Xcode
```

## Why a plain monorepo (not Turborepo)

Turbo orchestrates JS/TS build graphs — it can't build an Xcode target, so it adds
config for no gain here. `apps/web` is self-contained (its own `package.json` +
lockfile); `apps/ios` builds via Xcode. Netlify builds from `apps/web` via the
`base` setting in `netlify.toml`.

See `apps/ios/README.md` for iOS build steps and the remaining-work checklist.
```
