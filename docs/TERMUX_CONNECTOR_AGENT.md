# Termux Connector Agent

This is a GitHub bridge for Termux development tasks.

It does not give anyone direct SSH access to your phone. It works like this:

1. GitHub Actions builds/tests the app in GitHub cloud runner.
2. The release workflow publishes APK to GitHub Releases.
3. A task file is added to `termux-agent/inbox/` in GitHub.
4. Termux agent on your phone pulls the repo.
5. The agent asks before running the task unless `AGENT_AUTO_RUN=yes` is used.
6. The agent runs only allowlisted Android/dev/root tasks.
7. It writes output to `termux-agent/outbox/` and pushes it back to GitHub.

## One-time setup in Termux

```bash
pkg update -y
pkg upgrade -y
pkg install -y git nodejs curl
```

Clone and run:

```bash
git clone https://github.com/cryptojetsoftware000-hash/BIJOY-V1.git
cd BIJOY-V1
bash scripts/termux-connector-agent.sh
```

Fast mode:

```bash
AGENT_SLEEP_SECONDS=15 bash scripts/termux-connector-agent.sh
```

Auto-run mode:

```bash
AGENT_AUTO_RUN=yes AGENT_SLEEP_SECONDS=15 bash scripts/termux-connector-agent.sh
```

Use auto-run only when you trust your own GitHub task files.

## Latest APK URL

```text
https://github.com/cryptojetsoftware000-hash/BIJOY-V1/releases/download/debug-latest/app-debug.apk
```

## Task file format

Create a `.task` file inside `termux-agent/inbox/`.

Simple example:

```text
SERVER_CHECK
```

With package name:

```text
CLEAR_APP_DATA_ROOT
PACKAGE=com.example.bijoy_calculator
```

With screen recording duration:

```text
SCREENRECORD_SHORT
DURATION=10
```

## Allowed normal tasks

```text
PWD
LS
GIT_STATUS
GIT_PULL
SERVER_INSTALL
SERVER_CHECK
SERVER_START_ONCE
FLUTTER_PUB_GET
FLUTTER_BUILD_DEBUG_APK
DOWNLOAD_LATEST_APK
OPEN_LATEST_APK
DOWNLOAD_AND_OPEN_APK
COLLECT_SAFE_LOGS
COLLECT_LOGCAT
DOCTOR
RUN_ALL_CHECKS
```

## Allowed root/install tasks

```text
ROOT_CHECK
INSTALL_LATEST_APK_ROOT
DOWNLOAD_AND_INSTALL_APK_ROOT
UNINSTALL_APP_ROOT
CLEAR_APP_DATA_ROOT
STOP_APP_ROOT
START_APP_ROOT
RESTART_APP_ROOT
GRANT_COMMON_PERMISSIONS_ROOT
CLEAR_LOGCAT_ROOT
```

## Allowed Android debug tasks

```text
DUMPSYS_PACKAGE
DUMPSYS_ACTIVITY_TOP
LIST_APP_PROCESSES
LIST_PACKAGES_DEV
COLLECT_CRASH_LOGS
TAKE_SCREENSHOT
SCREENRECORD_SHORT
DEVICE_INFO_DEV
```

## Notes

- Root commands use `su`; Magisk/SuperSU may ask for permission.
- Root install uses `pm install -r`.
- Default package is `com.example.bijoy_calculator`; override with `PACKAGE=...` in the task file.
- `SCREENRECORD_SHORT` supports `DURATION=1` to `DURATION=60` seconds.
- Full arbitrary root shell is intentionally not implemented. For new projects, add new allowlisted task names instead.

## Stop the agent

Press:

```text
CTRL + C
```
