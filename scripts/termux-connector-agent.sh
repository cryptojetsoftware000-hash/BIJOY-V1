#!/data/data/com.termux/files/usr/bin/bash

set -u

# BIJOY-V1 Termux Connector Agent
# Safe GitHub bridge for Termux.
# It polls GitHub, reads task files from .termux-agent/inbox, runs ONLY allowlisted tasks,
# writes logs to .termux-agent/outbox, and pushes logs back to GitHub.

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
INBOX="$ROOT_DIR/.termux-agent/inbox"
DONE="$ROOT_DIR/.termux-agent/done"
OUTBOX="$ROOT_DIR/.termux-agent/outbox"
REJECTED="$ROOT_DIR/.termux-agent/rejected"
SLEEP_SECONDS="${AGENT_SLEEP_SECONDS:-60}"
AUTO_RUN="${AGENT_AUTO_RUN:-no}"

mkdir -p "$INBOX" "$DONE" "$OUTBOX" "$REJECTED"
cd "$ROOT_DIR" || exit 1

echo "========================================"
echo "BIJOY-V1 Termux Connector Agent"
echo "Repo: $ROOT_DIR"
echo "Inbox: $INBOX"
echo "Outbox: $OUTBOX"
echo "Mode: $([ "$AUTO_RUN" = "yes" ] && echo "AUTO RUN" || echo "ASK BEFORE RUN")"
echo "Interval: ${SLEEP_SECONDS}s"
echo "========================================"

safe_commit_push() {
  local msg="$1"
  git add .termux-agent || true
  if git diff --cached --quiet; then
    return 0
  fi
  git commit -m "$msg" || return 0
  git push || true
}

write_log() {
  local task_file="$1"
  local status="$2"
  local body="$3"
  local base
  base="$(basename "$task_file")"
  local log_file="$OUTBOX/${base%.task}.log"
  {
    echo "Task: $base"
    echo "Status: $status"
    echo "Time: $(date)"
    echo "Device: $(uname -a)"
    echo "----------------------------------------"
    echo "$body"
  } > "$log_file"
}

run_task() {
  local task_file="$1"
  local cmd
  cmd="$(tr -d '\r' < "$task_file" | sed '/^#/d;/^$/d' | head -n 1)"

  if [ -z "$cmd" ]; then
    write_log "$task_file" "REJECTED" "Empty task."
    mv "$task_file" "$REJECTED/$(basename "$task_file")"
    return
  fi

  echo ""
  echo "New task: $(basename "$task_file")"
  echo "Command: $cmd"

  if [ "$AUTO_RUN" != "yes" ]; then
    printf "Run this task? Type yes to continue: "
    read -r answer
    if [ "$answer" != "yes" ]; then
      write_log "$task_file" "REJECTED" "User rejected task: $cmd"
      mv "$task_file" "$REJECTED/$(basename "$task_file")"
      return
    fi
  fi

  local output status
  status="DONE"

  case "$cmd" in
    PWD)
      output="$(pwd 2>&1)"
      ;;
    LS)
      output="$(find . -maxdepth 3 -type f | sort 2>&1)"
      ;;
    GIT_STATUS)
      output="$(git status --short 2>&1)"
      ;;
    GIT_PULL)
      output="$(git pull 2>&1)"
      ;;
    SERVER_INSTALL)
      output="$(cd server && npm install 2>&1)"
      ;;
    SERVER_CHECK)
      output="$(cd server && npm install && npm run check 2>&1)"
      ;;
    SERVER_START_ONCE)
      output="$(cd server && timeout 20 npm start 2>&1 || true)"
      ;;
    FLUTTER_PUB_GET)
      output="$(cd flutter_app && flutter pub get 2>&1)"
      ;;
    FLUTTER_BUILD_DEBUG_APK)
      output="$(cd flutter_app && flutter create . --platforms=android && flutter pub get && flutter build apk --debug 2>&1)"
      ;;
    DOCTOR)
      output="$(bash scripts/doctor.sh 2>&1)"
      ;;
    RUN_ALL_CHECKS)
      output="$(bash scripts/run-all-checks.sh 2>&1)"
      ;;
    *)
      status="REJECTED"
      output="Command not allowed: $cmd

Allowed commands:
PWD
LS
GIT_STATUS
GIT_PULL
SERVER_INSTALL
SERVER_CHECK
SERVER_START_ONCE
FLUTTER_PUB_GET
FLUTTER_BUILD_DEBUG_APK
DOCTOR
RUN_ALL_CHECKS"
      ;;
  esac

  write_log "$task_file" "$status" "$output"

  if [ "$status" = "DONE" ]; then
    mv "$task_file" "$DONE/$(basename "$task_file")"
  else
    mv "$task_file" "$REJECTED/$(basename "$task_file")"
  fi
}

while true; do
  echo ""
  echo "[$(date)] Checking GitHub for tasks..."
  git pull --rebase || true

  found="no"
  for task_file in "$INBOX"/*.task; do
    [ -e "$task_file" ] || continue
    found="yes"
    run_task "$task_file"
    safe_commit_push "Termux agent result: $(basename "$task_file")"
  done

  if [ "$found" = "no" ]; then
    echo "No task found."
  fi

  sleep "$SLEEP_SECONDS"
done
