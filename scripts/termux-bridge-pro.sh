#!/data/data/com.termux/files/usr/bin/bash

set -u

# BIJOY-V1 Bridge Pro
# Faster GitHub <-> Termux bridge with queue, lock, heartbeat, state, and rich logs.
# This script still uses allowlisted tasks only. It is designed for fast app build/test/install/debug loops.

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
AGENT_DIR="$ROOT_DIR/termux-agent"
INBOX="$AGENT_DIR/inbox"
RUNNING="$AGENT_DIR/running"
DONE="$AGENT_DIR/done"
FAILED="$AGENT_DIR/failed"
REJECTED="$AGENT_DIR/rejected"
OUTBOX="$AGENT_DIR/outbox"
STATE="$AGENT_DIR/state"
DOWNLOADS="$AGENT_DIR/downloads"
LOCK_DIR="$AGENT_DIR/.lock"
SLEEP_SECONDS="${AGENT_SLEEP_SECONDS:-5}"
AUTO_RUN="${AGENT_AUTO_RUN:-no}"
HEARTBEAT_PUSH_EVERY="${AGENT_HEARTBEAT_PUSH_EVERY:-12}"
MAX_LOG_LINES="${AGENT_MAX_LOG_LINES:-1200}"
DEFAULT_APK_URL="${APK_URL:-https://github.com/cryptojetsoftware000-hash/BIJOY-V1/releases/download/debug-latest/app-debug.apk}"
APK_URL="$DEFAULT_APK_URL"
APK_FILE="$DOWNLOADS/app-debug.apk"
ROOT_APK_TMP="/data/local/tmp/bijoy-v1-app-debug.apk"

mkdir -p "$INBOX" "$RUNNING" "$DONE" "$FAILED" "$REJECTED" "$OUTBOX" "$STATE" "$DOWNLOADS"
cd "$ROOT_DIR" || exit 1

if ! mkdir "$LOCK_DIR" 2>/dev/null; then
  echo "Another Bridge Pro agent seems to be running. Lock: $LOCK_DIR"
  exit 1
fi
trap 'rm -rf "$LOCK_DIR"' EXIT INT TERM

log_console() {
  echo "[$(date '+%H:%M:%S')] $*"
}

git_config_once() {
  git config user.name >/dev/null 2>&1 || git config user.name "Termux Bridge Pro"
  git config user.email >/dev/null 2>&1 || git config user.email "termux-agent@local"
}

git_pull_fast() {
  git pull --rebase --autostash 2>&1 || git pull 2>&1 || true
}

git_push_agent_files() {
  local msg="$1"
  git add termux-agent 2>/dev/null || true
  if git diff --cached --quiet; then
    return 0
  fi
  git commit -m "$msg" >/dev/null 2>&1 || true
  git pull --rebase --autostash >/dev/null 2>&1 || true
  git push >/dev/null 2>&1 || true
}

write_heartbeat() {
  cat > "$STATE/heartbeat.txt" <<EOF
status=online
time=$(date -Iseconds)
device=$(uname -a)
repo=$ROOT_DIR
mode=$([ "$AUTO_RUN" = "yes" ] && echo auto || echo ask)
interval=${SLEEP_SECONDS}
apk_url=$APK_URL
EOF
}

read_command() {
  tr -d '\r' < "$1" | sed '/^#/d;/^$/d' | head -n 1
}

apply_task_config() {
  local task_file="$1"
  APK_URL="$DEFAULT_APK_URL"
  APK_FILE="$DOWNLOADS/app-debug.apk"
  ROOT_APK_TMP="/data/local/tmp/bijoy-v1-app-debug.apk"

  [ -f "$task_file" ] || return 0
  while IFS='=' read -r key value; do
    case "$key" in
      APK_URL)
        APK_URL="$value"
        ;;
      APK_NAME)
        value="$(echo "$value" | tr -cd 'A-Za-z0-9._-')"
        [ -n "$value" ] && APK_FILE="$DOWNLOADS/$value"
        ;;
    esac
  done < <(tr -d '\r' < "$task_file" | sed '1d;/^#/d;/^$/d')

  ROOT_APK_TMP="/data/local/tmp/$(basename "$APK_FILE")"
}

write_log_file() {
  local task_name="$1"
  local status="$2"
  local cmd="$3"
  local output="$4"
  local log_file="$OUTBOX/${task_name%.task}.log"
  {
    echo "task=$task_name"
    echo "status=$status"
    echo "command=$cmd"
    echo "time=$(date -Iseconds)"
    echo "device=$(uname -a)"
    echo "repo=$ROOT_DIR"
    echo "apk_url=$APK_URL"
    echo "apk_file=$APK_FILE"
    echo "----------------------------------------"
    echo "$output" | tail -n "$MAX_LOG_LINES"
  } > "$log_file"
}

download_latest_apk() {
  mkdir -p "$DOWNLOADS"
  rm -f "$APK_FILE"
  if command -v curl >/dev/null 2>&1; then
    curl -L --fail "$APK_URL" -o "$APK_FILE"
  elif command -v wget >/dev/null 2>&1; then
    wget -O "$APK_FILE" "$APK_URL"
  else
    echo "curl/wget not found. Run: pkg install -y curl"
    return 1
  fi
  ls -lh "$APK_FILE"
}

open_latest_apk() {
  [ -f "$APK_FILE" ] || download_latest_apk || return 1
  if command -v termux-open >/dev/null 2>&1; then
    termux-open "$APK_FILE"
  else
    am start -a android.intent.action.VIEW -d "file://$APK_FILE" -t "application/vnd.android.package-archive"
  fi
}

root_install_latest_apk() {
  command -v su >/dev/null 2>&1 || { echo "su not found"; return 1; }
  [ -f "$APK_FILE" ] || download_latest_apk || return 1
  su -c "cp '$APK_FILE' '$ROOT_APK_TMP' && chmod 644 '$ROOT_APK_TMP' && pm install -r '$ROOT_APK_TMP'"
  pm list packages 2>/dev/null | grep -i -E 'bijoy|calculator|notepad' || true
}

collect_safe_logs() {
  {
    echo "=== termux-info ==="
    command -v termux-info >/dev/null 2>&1 && termux-info || true
    echo "=== root ==="
    command -v su >/dev/null 2>&1 && su -c id || true
    echo "=== git ==="
    git status --short || true
    echo "=== agent state ==="
    find termux-agent -maxdepth 3 -type f -print 2>/dev/null | sort || true
    echo "=== apk ==="
    ls -lh "$APK_FILE" 2>/dev/null || true
    echo "=== packages ==="
    pm list packages 2>/dev/null | grep -i -E 'bijoy|calculator|notepad|debug|test' || true
  }
}

run_cmd() {
  local cmd="$1"
  local task_file="$2"
  case "$cmd" in
    PWD) pwd ;;
    LS) find . -maxdepth 4 -type f | sort ;;
    GIT_STATUS) git status --short ;;
    GIT_PULL) git_pull_fast ;;
    SERVER_INSTALL) cd server && npm install ;;
    SERVER_CHECK) cd server && npm install && npm run check ;;
    SERVER_START_ONCE) cd server && timeout 20 npm start || true ;;
    FLUTTER_PUB_GET) cd flutter_app && flutter pub get ;;
    FLUTTER_BUILD_DEBUG_APK) cd flutter_app && flutter create . --platforms=android && flutter pub get && flutter build apk --debug ;;
    NATIVE_NOTEPAD_BUILD_DEBUG_APK) cd android_notepad && gradle :app:assembleDebug ;;
    DOWNLOAD_LATEST_APK) download_latest_apk ;;
    OPEN_LATEST_APK) open_latest_apk ;;
    DOWNLOAD_AND_OPEN_APK) download_latest_apk && open_latest_apk ;;
    INSTALL_LATEST_APK_ROOT) root_install_latest_apk ;;
    DOWNLOAD_AND_INSTALL_APK_ROOT) download_latest_apk && root_install_latest_apk ;;
    ROOT_CHECK|UNINSTALL_APP_ROOT|CLEAR_APP_DATA_ROOT|STOP_APP_ROOT|START_APP_ROOT|RESTART_APP_ROOT|GRANT_COMMON_PERMISSIONS_ROOT|DUMPSYS_PACKAGE|DUMPSYS_ACTIVITY_TOP|LIST_APP_PROCESSES|LIST_PACKAGES_DEV|CLEAR_LOGCAT_ROOT|COLLECT_CRASH_LOGS|TAKE_SCREENSHOT|SCREENRECORD_SHORT|DEVICE_INFO_DEV)
      bash scripts/termux-root-dev-tools.sh "$cmd" "$task_file" ;;
    COLLECT_SAFE_LOGS) collect_safe_logs ;;
    COLLECT_LOGCAT) logcat -d -t 500 2>&1 || true ;;
    DOCTOR) bash scripts/doctor.sh ;;
    RUN_ALL_CHECKS) bash scripts/run-all-checks.sh ;;
    QUICK_APP_TEST)
      download_latest_apk
      root_install_latest_apk
      bash scripts/termux-root-dev-tools.sh CLEAR_LOGCAT_ROOT "$task_file" || true
      bash scripts/termux-root-dev-tools.sh RESTART_APP_ROOT "$task_file" || true
      sleep 5
      bash scripts/termux-root-dev-tools.sh COLLECT_CRASH_LOGS "$task_file" || true
      ;;
    *)
      echo "Command not allowed: $cmd"
      echo "Use docs/TERMUX_CONNECTOR_AGENT.md for allowlisted commands."
      return 2
      ;;
  esac
}

process_task() {
  local task_file="$1"
  local task_name cmd running_file output status code
  task_name="$(basename "$task_file")"
  cmd="$(read_command "$task_file")"
  running_file="$RUNNING/$task_name"
  apply_task_config "$task_file"

  [ -n "$cmd" ] || {
    write_log_file "$task_name" "REJECTED" "EMPTY" "Empty task file"
    mv "$task_file" "$REJECTED/$task_name"
    return
  }

  log_console "Task found: $task_name -> $cmd"

  if [ "$AUTO_RUN" != "yes" ]; then
    printf "Run task '%s'? Type yes: " "$cmd"
    read -r answer
    if [ "$answer" != "yes" ]; then
      write_log_file "$task_name" "REJECTED" "$cmd" "User rejected task."
      mv "$task_file" "$REJECTED/$task_name"
      return
    fi
  fi

  mv "$task_file" "$running_file"
  echo "task=$task_name" > "$STATE/current_task.txt"
  echo "command=$cmd" >> "$STATE/current_task.txt"
  echo "started=$(date -Iseconds)" >> "$STATE/current_task.txt"
  echo "apk_url=$APK_URL" >> "$STATE/current_task.txt"

  set +e
  output="$(run_cmd "$cmd" "$running_file" 2>&1)"
  code=$?
  set -e

  if [ "$code" -eq 0 ]; then
    status="DONE"
    mv "$running_file" "$DONE/$task_name"
  else
    status="FAILED"
    mv "$running_file" "$FAILED/$task_name"
  fi

  write_log_file "$task_name" "$status" "$cmd" "exit_code=$code
$output"
  rm -f "$STATE/current_task.txt"
  git_push_agent_files "Bridge Pro result: $task_name $status"
  log_console "Task $task_name finished: $status"
}

main() {
  set -e
  git_config_once
  write_heartbeat
  git_push_agent_files "Bridge Pro heartbeat"

  echo "========================================"
  echo "BIJOY-V1 Bridge Pro started"
  echo "Mode: $([ "$AUTO_RUN" = "yes" ] && echo AUTO || echo ASK)"
  echo "Interval: ${SLEEP_SECONDS}s"
  echo "Inbox: $INBOX"
  echo "Outbox: $OUTBOX"
  echo "========================================"

  local cycle=0 found task_file
  while true; do
    cycle=$((cycle + 1))
    log_console "Pulling GitHub tasks..."
    git_pull_fast >/dev/null 2>&1 || true
    write_heartbeat

    found="no"
    for task_file in $(find "$INBOX" -maxdepth 1 -type f -name '*.task' | sort); do
      found="yes"
      process_task "$task_file"
    done

    if [ "$found" = "no" ]; then
      log_console "No task."
    fi

    if [ $((cycle % HEARTBEAT_PUSH_EVERY)) -eq 0 ]; then
      git_push_agent_files "Bridge Pro heartbeat"
    fi

    sleep "$SLEEP_SECONDS"
  done
}

main
