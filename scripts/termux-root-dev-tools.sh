#!/data/data/com.termux/files/usr/bin/bash

set -u

# Safe root/dev helper for BIJOY-V1 Termux agent.
# This is NOT an unlimited shell. It only runs allowlisted Android development tasks.

CMD="${1:-}"
TASK_FILE="${2:-}"
DEFAULT_PACKAGE="com.example.bijoy_calculator"
PACKAGE="${AGENT_APP_PACKAGE:-$DEFAULT_PACKAGE}"
DURATION="10"
ROOT_TMP_DIR="/data/local/tmp"
SCREEN_DIR="/sdcard/Download"

read_config() {
  [ -n "$TASK_FILE" ] && [ -f "$TASK_FILE" ] || return 0
  while IFS='=' read -r key value; do
    case "$key" in
      PACKAGE) PACKAGE="$value" ;;
      DURATION) DURATION="$value" ;;
    esac
  done < <(tr -d '\r' < "$TASK_FILE" | sed '1d;/^#/d;/^$/d')
}

validate_package() {
  echo "$PACKAGE" | grep -Eq '^[A-Za-z0-9_]+(\.[A-Za-z0-9_]+)+$'
}

validate_duration() {
  echo "$DURATION" | grep -Eq '^[0-9]+$' || DURATION=10
  if [ "$DURATION" -lt 1 ]; then DURATION=1; fi
  if [ "$DURATION" -gt 60 ]; then DURATION=60; fi
}

need_su() {
  command -v su >/dev/null 2>&1 || { echo "su not found"; exit 1; }
}

safe_pkg() {
  read_config
  validate_package || { echo "Invalid PACKAGE: $PACKAGE"; exit 1; }
}

case "$CMD" in
  ROOT_CHECK)
    need_su
    su -c id
    ;;

  UNINSTALL_APP_ROOT)
    need_su
    safe_pkg
    echo "Uninstalling: $PACKAGE"
    su -c "pm uninstall '$PACKAGE'" || su -c "pm uninstall --user 0 '$PACKAGE'"
    ;;

  CLEAR_APP_DATA_ROOT)
    need_su
    safe_pkg
    echo "Clearing app data: $PACKAGE"
    su -c "pm clear '$PACKAGE'"
    ;;

  STOP_APP_ROOT)
    need_su
    safe_pkg
    echo "Force stopping: $PACKAGE"
    su -c "am force-stop '$PACKAGE'"
    ;;

  START_APP_ROOT)
    need_su
    safe_pkg
    echo "Starting app with monkey: $PACKAGE"
    su -c "monkey -p '$PACKAGE' -c android.intent.category.LAUNCHER 1"
    ;;

  RESTART_APP_ROOT)
    need_su
    safe_pkg
    echo "Restarting: $PACKAGE"
    su -c "am force-stop '$PACKAGE'"
    sleep 1
    su -c "monkey -p '$PACKAGE' -c android.intent.category.LAUNCHER 1"
    ;;

  GRANT_COMMON_PERMISSIONS_ROOT)
    need_su
    safe_pkg
    echo "Granting common runtime permissions to: $PACKAGE"
    for perm in \
      android.permission.POST_NOTIFICATIONS \
      android.permission.CAMERA \
      android.permission.RECORD_AUDIO \
      android.permission.ACCESS_FINE_LOCATION \
      android.permission.ACCESS_COARSE_LOCATION \
      android.permission.READ_EXTERNAL_STORAGE \
      android.permission.WRITE_EXTERNAL_STORAGE \
      android.permission.BLUETOOTH_CONNECT; do
      su -c "pm grant '$PACKAGE' '$perm'" 2>/dev/null || true
    done
    echo "Permission grant attempts finished."
    ;;

  DUMPSYS_PACKAGE)
    safe_pkg
    dumpsys package "$PACKAGE" 2>&1 | head -n 500
    ;;

  DUMPSYS_ACTIVITY_TOP)
    dumpsys activity activities 2>&1 | head -n 500
    ;;

  LIST_APP_PROCESSES)
    safe_pkg
    ps -A 2>/dev/null | grep "$PACKAGE" || true
    ;;

  LIST_PACKAGES_DEV)
    pm list packages 2>/dev/null | grep -i -E 'bijoy|calculator|debug|test' || true
    ;;

  CLEAR_LOGCAT_ROOT)
    need_su
    su -c "logcat -c"
    echo "Logcat cleared."
    ;;

  COLLECT_CRASH_LOGS)
    safe_pkg
    echo "Crash/runtime logs for $PACKAGE"
    logcat -d -t 1000 2>&1 | grep -i -E "$PACKAGE|AndroidRuntime|FATAL EXCEPTION|crash|fatal|exception" | tail -n 500 || true
    ;;

  TAKE_SCREENSHOT)
    mkdir -p "$SCREEN_DIR"
    FILE="$SCREEN_DIR/bijoy-agent-screenshot-$(date +%Y%m%d-%H%M%S).png"
    screencap -p "$FILE"
    ls -lh "$FILE"
    ;;

  SCREENRECORD_SHORT)
    validate_duration
    mkdir -p "$SCREEN_DIR"
    FILE="$SCREEN_DIR/bijoy-agent-record-$(date +%Y%m%d-%H%M%S).mp4"
    echo "Recording screen for ${DURATION}s to $FILE"
    timeout "$((DURATION + 3))" screenrecord --time-limit "$DURATION" "$FILE" 2>&1 || true
    ls -lh "$FILE" 2>/dev/null || true
    ;;

  DEVICE_INFO_DEV)
    {
      echo "=== getprop summary ==="
      getprop ro.product.manufacturer
      getprop ro.product.model
      getprop ro.build.version.release
      getprop ro.build.version.sdk
      echo "=== storage ==="
      df -h | head -n 30
      echo "=== battery ==="
      dumpsys battery | head -n 80
    }
    ;;

  *)
    echo "Unknown safe root/dev task: $CMD"
    exit 2
    ;;
esac
