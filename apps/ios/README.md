# fitOS — Native iOS app

Native SwiftUI client for fitOS. It talks to the **same backend** as the web app
(`apps/web`, hosted at `https://fit.berjiljacob.com`) — same accounts, same data,
same `/api/*` endpoints. No backend is duplicated; only the UI is native.

## Requirements

- Xcode 15+ (iOS 16 deployment target — Swift Charts needs 16)
- [XcodeGen](https://github.com/yonyz/XcodeGen) to generate the `.xcodeproj` from `project.yml`:
  ```bash
  brew install xcodegen
  ```

## Build & run

```bash
cd apps/ios
xcodegen generate      # writes fitOS.xcodeproj from project.yml
open fitOS.xcodeproj    # then ⌘R in Xcode on a simulator or device
```

The `.xcodeproj` is git-ignored on purpose — it is generated from `project.yml`,
which is the source of truth. Regenerate it any time sources change.

Signing team `929G58HJFN` (same as the old Tauri shell) is baked into `project.yml`.

## Architecture

```
Sources/fitOS/
  fitOSApp.swift          @main entry, injects AppState, dark + red theme
  Support/
    Theme.swift           palette mirrored from apps/web/src/app.css
    Models.swift          Codable mirrors of apps/web/src/lib/types.ts
    Nutrition.swift       Mifflin-St Jeor TDEE + macro targets
    APIClient.swift       URLSession + cookie session against /api/*
    AppState.swift        ObservableObject: hydrate /api/state, push per key
  Views/
    RootView / LoginView / MainTabView
    TodayView             calorie ring + macro bars + today's meals
    FoodView              catalog browse/search + log-to-meal sheet
    WorkoutView           exercise catalog browse/search
    ProgressScreen        Swift Charts weight trend + BMI + log weight
    ProfileView           edit profile + targets + logout
Resources/Assets.xcassets AccentColor (fitOS red) + AppIcon slot
```

**Data flow** (mirrors the web's synced stores):
- Login/register → cookie session stored by URLSession.
- `hydrate()` pulls `/api/catalog` (foods+exercises) and `/api/state` (profile,
  log, weightlog, custom foods/exercises).
- Every mutation updates local `@Published` state and debounce-pushes the changed
  `luxifit.*` key back via `PUT /api/state/{key}` — so web + iOS stay in sync.

## Remaining work (mechanical — follow the existing view patterns)

- [ ] **Workout logging** — sets/reps/weight per session + `luxifit.workoutplan` /
      workout day-log key (web uses `luxifit.workoutplan`; confirm the day-log key).
- [ ] **Meal plan** (`luxifit.weekplan`) — weekday routine editor, like the web.
- [ ] **Voice logging** — record audio, POST transcript to `/api/voice/parse`,
      apply returned items (web has `VoiceLogButton`).
- [ ] **Anatomy / body map** — the web renders SVG paths (`body-paths.ts`); port
      to SwiftUI `Path`s or a lightweight SVG renderer. This is the heaviest screen.
- [ ] **Custom foods/exercises** — add-food form → append to `luxifit.foods`.
- [ ] **Reconcile calorie/macro targets** in `Nutrition.swift` with the web's
      `TodayView` so both platforms show identical numbers.
- [ ] **HealthKit** — add the entitlement + `NSHealthShareUsageDescription`, read
      weight/steps. (This is the one genuinely-native win for a fitness app.)
- [ ] **FaceID unlock**, haptics on log actions, push notifications.
- [ ] Drop the flex logo into `Assets.xcassets/AppIcon.appiconset` (1024²).
```
