#!/usr/bin/env bash
# Install / uninstall daily fitOS auto-install at 22:00 (10 PM) local time.
# Works on any Mac after clone — paths are computed for THIS machine.
set -euo pipefail

REPO_SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
IOS_DIR="$(cd "${REPO_SCRIPT_DIR}/.." && pwd)"
SUPPORT="${HOME}/Library/Application Support/fitOS"
RUNNER="${SUPPORT}/auto-install-device.sh"
LABEL="com.berjil.fitos.autoinstall"
PLIST_DST="${HOME}/Library/LaunchAgents/${LABEL}.plist"
UID_NUM="$(id -u)"

# Daily at 10:00 PM local
HOUR=22
MINUTE=0

mkdir -p "$SUPPORT" "${HOME}/Library/LaunchAgents" "${HOME}/Library/Logs/fitOS"

cmd="${1:-install}"

# Copy runner out of the repo (LaunchAgents cannot always read ~/Documents)
install_runner() {
  cp "${REPO_SCRIPT_DIR}/auto-install-device.sh" "$RUNNER"
  chmod +x "$RUNNER"
  # So the Application Support copy always knows where the project lives
  echo "$IOS_DIR" >"${SUPPORT}/ios-dir.conf"
}

case "$cmd" in
  install|enable)
    install_runner
    cat >"$PLIST_DST" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>${LABEL}</string>
  <key>ProgramArguments</key>
  <array>
    <string>/bin/bash</string>
    <string>${RUNNER}</string>
  </array>
  <key>EnvironmentVariables</key>
  <dict>
    <key>FITOS_IOS_DIR</key>
    <string>${IOS_DIR}</string>
  </dict>
  <key>StartCalendarInterval</key>
  <dict>
    <key>Hour</key>
    <integer>${HOUR}</integer>
    <key>Minute</key>
    <integer>${MINUTE}</integer>
  </dict>
  <key>RunAtLoad</key>
  <false/>
  <key>StandardOutPath</key>
  <string>${HOME}/Library/Logs/fitOS/launchd.out.log</string>
  <key>StandardErrorPath</key>
  <string>${HOME}/Library/Logs/fitOS/launchd.err.log</string>
  <key>ProcessType</key>
  <string>Background</string>
</dict>
</plist>
EOF
    launchctl bootout "gui/${UID_NUM}/${LABEL}" 2>/dev/null || true
    launchctl bootstrap "gui/${UID_NUM}" "$PLIST_DST"
    launchctl enable "gui/${UID_NUM}/${LABEL}" 2>/dev/null || true
    echo "✓ Auto-install ON for this Mac"
    echo "  • Every day at ${HOUR}:$(printf '%02d' $MINUTE) (10 PM local)"
    echo "  • Project: ${IOS_DIR}"
    echo "  • Phone must be unlocked + paired to THIS Mac"
    echo "  • Log: ~/Library/Logs/fitOS/auto-install.log"
    echo
    echo "Manual now:  bash \"${RUNNER}\" --force"
    echo "Status:      bash \"${RUNNER}\" --status"
    echo "Turn off:    bash \"${REPO_SCRIPT_DIR}/setup-auto-install.sh\" uninstall"
    ;;
  uninstall|disable|remove)
    launchctl bootout "gui/${UID_NUM}/${LABEL}" 2>/dev/null || true
    rm -f "$PLIST_DST"
    echo "✓ Auto-install OFF on this Mac"
    ;;
  status)
    if [[ -x "$RUNNER" ]]; then
      bash "$RUNNER" --status
    else
      echo "Runner not installed. Run: $0 install"
    fi
    ;;
  run|now)
    install_runner
    bash "$RUNNER" --force
    ;;
  *)
    echo "Usage: $0 [install|uninstall|status|run]"
    exit 1
    ;;
esac
