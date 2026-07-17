#!/usr/bin/env bash
# Rebuild + install fitOS onto a paired/connected physical iPhone.
# Free Apple signing expires ~7 days — run daily via LaunchAgent.
#
# First-time (any Mac / any phone):
#   1. Clone repo, open apps/ios in Xcode once, select your Team, Run (⌘R)
#   2. bash apps/ios/scripts/setup-auto-install.sh install
#   3. Keep Mac on near 22:00 with phone unlocked + paired
#
set -euo pipefail

export PATH="/usr/bin:/bin:/usr/sbin:/sbin:/opt/homebrew/bin:/usr/local/bin:${PATH:-}"
if [[ -x /usr/bin/xcode-select ]]; then
  DEVELOPER_DIR="$(/usr/bin/xcode-select -p 2>/dev/null || true)"
  if [[ -n "${DEVELOPER_DIR:-}" ]]; then
    export DEVELOPER_DIR
    export PATH="${DEVELOPER_DIR}/usr/bin:${PATH}"
  fi
fi

# Repo path: env → config next to this script → discover from repo layout
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
if [[ -z "${FITOS_IOS_DIR:-}" && -f "${SCRIPT_DIR}/ios-dir.conf" ]]; then
  # shellcheck disable=SC1091
  # file contains a single line path
  FITOS_IOS_DIR="$(tr -d '[:space:]' <"${SCRIPT_DIR}/ios-dir.conf")"
fi
if [[ -n "${FITOS_IOS_DIR:-}" ]]; then
  IOS_DIR="$FITOS_IOS_DIR"
elif [[ -d "${SCRIPT_DIR}/../Sources" ]]; then
  IOS_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
elif [[ -d "${SCRIPT_DIR}/../../apps/ios/Sources" ]]; then
  IOS_DIR="$(cd "${SCRIPT_DIR}/../../apps/ios" && pwd)"
else
  IOS_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
fi

LOG_DIR="${HOME}/Library/Logs/fitOS"
DD_DIR="${HOME}/Library/Application Support/fitOS/DerivedData"
LOG_FILE="${LOG_DIR}/auto-install.log"
STAMP_FILE="${LOG_DIR}/last-success.txt"
MIN_INTERVAL_SEC=$(( 20 * 60 * 60 ))  # 20h throttle unless --force
BUNDLE_ID="${FITOS_BUNDLE_ID:-com.berjil.fitos}"

mkdir -p "$LOG_DIR" "$DD_DIR"

log() {
  local line="[$(date '+%Y-%m-%d %H:%M:%S')] $*"
  echo "$line" | tee -a "$LOG_FILE"
}

device_line() {
  xcrun devicectl list devices 2>/dev/null | grep -E 'available \(paired\)|connected' || true
}

if [[ "${1:-}" == "--status" ]]; then
  echo "iOS dir: $IOS_DIR"
  echo "Log:     $LOG_FILE"
  [[ -f "$STAMP_FILE" ]] && echo "Last OK: $(cat "$STAMP_FILE")" || echo "Last OK: (never)"
  echo "Devices:"
  device_line || echo "  (none)"
  launchctl print "gui/$(id -u)/com.berjil.fitos.autoinstall" 2>/dev/null | head -10 || echo "LaunchAgent: not loaded"
  exit 0
fi

FORCE=0
[[ "${1:-}" == "--force" ]] && FORCE=1

if [[ "$FORCE" -eq 0 && -f "${LOG_DIR}/last-success.epoch" ]]; then
  epoch=$(cat "${LOG_DIR}/last-success.epoch")
  now=$(date +%s)
  age=$(( now - epoch ))
  if (( age < MIN_INTERVAL_SEC )); then
    log "Skip — last success ${age}s ago. Use --force to override."
    exit 0
  fi
fi

if ! device_line | grep -q .; then
  log "Skip — no iPhone connected/paired (unlock phone, same Wi‑Fi or cable, Trust Mac)."
  exit 0
fi

# First available physical device UUID from devicectl
DEVICE_CORE_ID=$(device_line \
  | grep -Eo '[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12}' \
  | head -1 || true)

if [[ -z "${DEVICE_CORE_ID:-}" ]]; then
  log "Skip — could not parse device id."
  exit 0
fi

log "=== fitOS auto-install start (device=$DEVICE_CORE_ID) ==="
log "Project: $IOS_DIR"

if [[ ! -d "$IOS_DIR" ]]; then
  log "ERROR: iOS project missing at $IOS_DIR"
  exit 1
fi

# Repo root is two levels up from apps/ios (…/fitOS)
REPO_ROOT="$(cd "$IOS_DIR/../.." && pwd)"
if [[ ! -d "${REPO_ROOT}/.git" ]]; then
  # Fallback: apps/ios is directly under repo
  if [[ -d "${IOS_DIR}/../.git" ]]; then
    REPO_ROOT="$(cd "$IOS_DIR/.." && pwd)"
  fi
fi

# Best-effort git pull. ANY failure is non-fatal — we always continue and
# rebuild + install from whatever is on disk locally.
# Skip only if FITOS_SKIP_GIT_PULL=1 or no .git.
if [[ "${FITOS_SKIP_GIT_PULL:-0}" != "1" && -d "${REPO_ROOT}/.git" ]]; then
  log "Git pull (best-effort) in ${REPO_ROOT}…"
  set +e
  (
    set +e
    cd "$REPO_ROOT" || exit 0
    DIRTY=0
    if [[ -n "$(git status --porcelain 2>/dev/null)" ]]; then
      DIRTY=1
      git stash push -u -m "fitOS auto-install $(date '+%Y-%m-%d %H:%M:%S')" >>"$LOG_FILE" 2>&1
    fi
    if git pull --ff-only >>"$LOG_FILE" 2>&1; then
      log "Git: fast-forward OK ($(git rev-parse --short HEAD 2>/dev/null || echo '?'))"
    else
      log "WARN: git pull failed — continuing with LOCAL tree (rebuild still runs)"
    fi
    if [[ "$DIRTY" -eq 1 ]]; then
      if ! git stash pop >>"$LOG_FILE" 2>&1; then
        log "WARN: stash pop had issues — local changes may need manual check; rebuild still runs"
      fi
    fi
    exit 0
  )
  set -e
  log "Proceeding to rebuild from local project (git success or fail does not stop install)"
else
  log "Git pull skipped (no .git or FITOS_SKIP_GIT_PULL=1) — rebuilding from local project"
fi

cd "$IOS_DIR"

if command -v xcodegen >/dev/null 2>&1; then
  xcodegen generate >>"$LOG_FILE" 2>&1 || log "WARN: xcodegen failed (continuing)"
fi

# Prefer any connected physical iOS destination from xcodebuild
DEST=""
if xcodebuild -showdestinations -scheme fitOS 2>/dev/null | grep -q 'platform:iOS,'; then
  DEST=$(xcodebuild -showdestinations -scheme fitOS 2>/dev/null \
    | grep 'platform:iOS,' | grep -v Simulator | head -1 \
    | grep -Eo 'id:[^,}]+' | head -1 | sed 's/^id:/id=/' || true)
fi
if [[ -z "${DEST:-}" ]]; then
  log "ERROR: no physical iOS destination in Xcode. Open Xcode → select your iPhone → Run once."
  exit 1
fi

log "Building (destination=$DEST)…"

set +e
xcodebuild \
  -scheme fitOS \
  -destination "$DEST" \
  -configuration Debug \
  -allowProvisioningUpdates \
  -derivedDataPath "$DD_DIR" \
  build >>"$LOG_FILE" 2>&1
BUILD_RC=$?
set -e

if [[ $BUILD_RC -ne 0 ]]; then
  log "ERROR: xcodebuild failed (exit $BUILD_RC). Last log lines:"
  tail -40 "$LOG_FILE"
  exit 1
fi

APP="${DD_DIR}/Build/Products/Debug-iphoneos/fitOS.app"
if [[ ! -d "$APP" ]]; then
  APP=$(ls -dt "${HOME}"/Library/Developer/Xcode/DerivedData/fitOS-*/Build/Products/Debug-iphoneos/fitOS.app 2>/dev/null | head -1 || true)
fi
if [[ -z "${APP:-}" || ! -d "$APP" ]]; then
  log "ERROR: fitOS.app not found after build."
  exit 1
fi
log "App: $APP"

set +e
xcrun devicectl device install app --device "$DEVICE_CORE_ID" "$APP" >>"$LOG_FILE" 2>&1
INST_RC=$?
set -e

if [[ $INST_RC -ne 0 ]]; then
  log "ERROR: install failed (rc=$INST_RC). Unlock phone and trust this Mac."
  exit 1
fi

xcrun devicectl device process launch --device "$DEVICE_CORE_ID" "$BUNDLE_ID" >>"$LOG_FILE" 2>&1 \
  || log "WARN: installed OK, launch failed (open fitOS manually)."

date '+%Y-%m-%d %H:%M:%S' >"$STAMP_FILE"
date +%s >"${LOG_DIR}/last-success.epoch"
log "=== SUCCESS — fitOS installed & ready ==="
exit 0
