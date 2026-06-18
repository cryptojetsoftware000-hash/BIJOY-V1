# BIJOY-V1 Bridge Pro

Bridge Pro is a faster GitHub-to-Termux development bridge.

It is not a live Codex terminal, but it is optimized for a fast build/test/install/debug loop:

```text
ChatGPT writes code/tasks in GitHub
→ GitHub Actions builds/tests APK
→ Bridge Pro pulls task files every few seconds
→ Termux runs allowlisted dev/root tasks
→ Logs/state are pushed back to GitHub
→ ChatGPT reads logs and fixes code
```

## Install/update in Termux

```bash
cd BIJOY-V1
git pull
bash scripts/install-bridge-pro-termux.sh
```

## Run Bridge Pro

Ask-before-run mode:

```bash
bash scripts/termux-bridge-pro.sh
```

Fast auto mode:

```bash
AGENT_AUTO_RUN=yes AGENT_SLEEP_SECONDS=5 bash scripts/termux-bridge-pro.sh
```

Ultra fast mode:

```bash
AGENT_AUTO_RUN=yes AGENT_SLEEP_SECONDS=2 bash scripts/termux-bridge-pro.sh
```

## Task files

Tasks are files ending with `.task` in:

```text
termux-agent/inbox/
```

The first non-empty non-comment line is the command.

Example:

```text
QUICK_APP_TEST
PACKAGE=com.example.bijoy_calculator
```

## Best tasks for app development

Build/install/test latest APK with root and collect crash logs:

```text
QUICK_APP_TEST
PACKAGE=com.example.bijoy_calculator
```

Install latest APK silently with root:

```text
DOWNLOAD_AND_INSTALL_APK_ROOT
```

Collect crash logs:

```text
COLLECT_CRASH_LOGS
PACKAGE=com.example.bijoy_calculator
```

Restart app:

```text
RESTART_APP_ROOT
PACKAGE=com.example.bijoy_calculator
```

Clear app data:

```text
CLEAR_APP_DATA_ROOT
PACKAGE=com.example.bijoy_calculator
```

Screen record:

```text
SCREENRECORD_SHORT
DURATION=10
```

## State files

Bridge Pro writes current state here:

```text
termux-agent/state/heartbeat.txt
termux-agent/state/current_task.txt
```

Results are written here:

```text
termux-agent/outbox/*.log
```

Completed/failed/rejected tasks are moved to:

```text
termux-agent/done/
termux-agent/failed/
termux-agent/rejected/
```

## Why this is faster than old agent

- Default 5-second polling instead of 60 seconds
- Lock file prevents two agents running together
- Heartbeat state shows phone online/offline
- Running/done/failed/rejected queues
- Better git pull/push with rebase/autostash
- Better log truncation to avoid huge GitHub commits
- QUICK_APP_TEST combines download + root install + app start + crash log

## Limits

Bridge Pro is still GitHub-poll based, not a live terminal stream. GitHub-based control usually has a few seconds delay. For true live execution, you need a local tool like Codex CLI running directly inside Termux or an ADB/SSH connector.
