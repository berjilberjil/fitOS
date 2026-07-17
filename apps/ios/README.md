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
    Nutrition.swift       Mifflin-St Jeor TDEE + macro targets (mirrors utils/nutrition.ts)
    APIClient.swift       URLSession + cookie session against /api/*
    AppState.swift        ObservableObject: hydrate /api/catalog + /api/state, push per key
    SVGPath.swift         pure-native SVG path parser (arc→bezier) for the body map
    HealthService.swift   HealthKit read/write weight + steps
    VoiceService.swift    Speech-framework transcription → /api/voice/parse
    BiometricLock.swift   optional Face ID app lock
    Haptics.swift         haptic feedback on log actions
  Views/
    RootView / LoginView / MainTabView
    TodayView             calorie ring + macro bars + today's meals
    FoodView              catalog browse/search + log-to-meal sheet (+ Editors, PickerSheets)
    WorkoutView           exercise catalog + WorkoutPlanView / WorkoutSessionView
    AnatomyView           tappable front/back body map + MuscleDetail + activation list
    MealPlanView          weekly meal routine editor
    ProgressScreen        Swift Charts weight trend + BMI + log weight (+ HealthKit)
    ProfileView           edit profile + targets + logout
    VoiceLogSheet         record → transcribe → parse → apply
    GIFView               pure-ImageIO GIF player for exercise demos
Resources/Assets.xcassets AccentColor (fitOS red) + AppIcon
```

**Data flow** (mirrors the web's synced stores):
- Login/register → cookie session stored by URLSession.
- `hydrate()` pulls `/api/catalog` (foods+exercises) and `/api/state` (profile,
  log, weightlog, custom foods/exercises).
- Every mutation updates local `@Published` state and debounce-pushes the changed
  `luxifit.*` key back via `PUT /api/state/{key}` — so web + iOS stay in sync.

## Status — full parity reached

The native app has **full feature parity** with the web app, plus native-only
wins. All of the original checklist is done:

- [x] Workout logging (`luxifit.workoutlog`) + weekly plan (`luxifit.workoutplan`)
- [x] Meal plan (`luxifit.weekplan`) weekday routine editor
- [x] Voice logging — Speech framework → `/api/voice/parse` → apply items
- [x] Anatomy / body map — native `SVGPath.swift` parser (handles SVGO-compacted
      paths), tappable front/back map + muscle detail + activation list
- [x] Custom foods/exercises CRUD (writes the full list to `luxifit.foods` /
      `luxifit.exercises`)
- [x] Nutrition targets reconciled with the web (`Nutrition.swift` ↔ `utils/nutrition.ts`)
- [x] **HealthKit** — read/write weight + steps (auto-registered via
      `-allowProvisioningUpdates`)
- [x] **Face ID** app lock, haptics on log actions
- [x] App icon in `Assets.xcassets/AppIcon.appiconset`

**How to keep it at parity:** when a new `luxifit.*` key or catalog field is added
in `apps/web`, mirror the type in `Support/Models.swift`, add it to `AppState`
(hydrate + debounced `PUT /api/state/{key}`), and build the SwiftUI screen. See the
root `README.md` → "How to make changes" for the full recipe. Regenerate the
project (`npm run ios:gen`) whenever Swift files are added.
```
