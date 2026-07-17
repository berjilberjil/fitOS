# fitOS on a free Apple account (you or a friend)

The App Store / TestFlight need a **paid** Apple Developer account ($99/yr).  
Without that, each install lasts **~7 days**, then must be reinstalled from a Mac.

## One-time setup (friend on THEIR Mac + THEIR iPhone)

### 0. Requirements
- Mac with **Xcode** installed (from App Store)
- iPhone unlocked, USB cable (or Wi‑Fi after first pair)
- Free **Apple ID** signed into Xcode

### 1. Clone the repo
```bash
git clone <repo-url> fitOS
cd fitOS
```

### 2. First install from Xcode (required once)
```bash
cd apps/ios
# optional if you have it: brew install xcodegen && xcodegen generate
open fitOS.xcodeproj
```

In Xcode:
1. Select the **fitOS** target → **Signing & Capabilities**
2. **Team** = your (friend’s) personal Apple ID team  
3. If Xcode complains about bundle id, change it to something unique, e.g. `com.yourname.fitos`
4. Plug in the iPhone → Trust computer → enable **Developer Mode** on the phone  
5. Select the iPhone as run destination → press **Run (⌘R)**

App should open on the phone. Log in / create a fitOS account (same website backend).

### 3. Turn on daily auto re-install (10 PM)
From the repo root (or `apps/ios/scripts`):

```bash
bash apps/ios/scripts/setup-auto-install.sh install
```

That schedules a job on **this Mac only** for **22:00 (10 PM)** every day:
- `git pull --ff-only` to get the latest code from GitHub (**best-effort**)
- if pull **fails** (offline, auth, conflicts) → **still rebuilds from the local clone**
- rebuilds fitOS and installs onto whichever iPhone is currently paired/connected
- skips quietly if the phone is offline

### 4. Optional: install right now
```bash
bash apps/ios/scripts/setup-auto-install.sh run
```

### 5. Check status / logs
```bash
bash apps/ios/scripts/setup-auto-install.sh status
# full log:
open ~/Library/Logs/fitOS/auto-install.log
```

### 6. Turn off later
```bash
bash apps/ios/scripts/setup-auto-install.sh uninstall
```

---

## What happens automatically?

| When | What |
|------|------|
| Every day **10:00 PM** | Mac: `git pull` (best-effort) → rebuild + reinstall fitOS |
| Pull fails | Still rebuilds **local** code and installs — install is never blocked by git |
| Phone **paired + unlocked** | Install succeeds → another ~7 days of use |
| Phone off / Mac asleep | That night is skipped; tries again next day |
| After reinstall | **Server data stays** if you log into the same account |

**Data:** food, weight, workouts, progress photo metadata live on `fit.berjiljacob.com` (login). Photo files live in Cloudflare R2.  
**Not synced:** theme, local reminder toggles (re-enable notifications once after reinstall).

More detail (scripts, env overrides): root [`README.md`](../../README.md) → **Daily auto rebuild**.

---

## Important limits (free Apple)

- Auto-install runs on **each person’s own Mac** — cloning the repo does **not** auto-enable the job until they run `setup-auto-install.sh install`.
- Friend’s phone is signed with **friend’s Apple ID**, not yours.
- You cannot send them a public install link without paid Developer + TestFlight.
- They can always use the **web app**: https://fit.berjiljacob.com (no 7-day limit).

---

## Quick checklist for your friend

- [ ] Install Xcode  
- [ ] `git clone` the repo  
- [ ] Xcode → Team + Run on their iPhone once  
- [ ] `bash apps/ios/scripts/setup-auto-install.sh install`  
- [ ] Leave Mac on around 10 PM with phone nearby/unlocked sometimes  
- [ ] Create fitOS login (or use web)  
