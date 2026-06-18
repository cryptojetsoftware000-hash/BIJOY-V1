# Termux Connector Agent

This is a safe GitHub bridge for Termux.

It does not give anyone direct SSH access to your phone. Instead, it works like this:

1. GitHub Actions builds and tests the app in GitHub cloud runner.
2. The release workflow publishes the APK to GitHub Releases.
3. A task file is added to `termux-agent/inbox/` in GitHub.
4. The Termux agent running on your phone pulls the repo.
5. The agent asks you before running the task.
6. The agent runs only allowed commands.
7. The agent downloads/opens/installs APK or collects logs.
8. The agent writes output to `termux-agent/outbox/` and pushes it back to GitHub.

## One-time setup in Termux

```bash
pkg update -y
pkg upgrade -y
pkg install -y git nodejs curl
```

Clone the repo:

```bash
git clone https://github.com/cryptojetsoftware000-hash/BIJOY-V1.git
cd BIJOY-V1
```

Run the agent:

```bash
bash scripts/termux-connector-agent.sh
```

## Faster checking

Default check interval is 60 seconds. To check every 15 seconds:

```bash
AGENT_SLEEP_SECONDS=15 bash scripts/termux-connector-agent.sh
```

## Auto-run mode

By default, the agent asks you before running any task. Auto-run mode is possible:

```bash
AGENT_AUTO_RUN=yes bash scripts/termux-connector-agent.sh
```

Use auto-run only if you fully trust the tasks in your GitHub repo.

## Direct APK download URL

After the GitHub release workflow succeeds, latest APK will be here:

```text
https://github.com/cryptojetsoftware000-hash/BIJOY-V1/releases/download/debug-latest/app-debug.apk
```

## Install latest APK from Termux

Normal non-root install opens Android installer:

```text
DOWNLOAD_AND_OPEN_APK
```

Root install can run silent install using `su` + `pm install -r`:

```text
DOWNLOAD_AND_INSTALL_APK_ROOT
```

Root check task:

```text
ROOT_CHECK
```

Install an already downloaded APK with root:

```text
INSTALL_LATEST_APK_ROOT
```

On rooted devices, Magisk/SuperSU may still ask once for permission. Allow Termux root access only if you trust your own repo tasks.

## Allowed task commands

Create a `.task` file in `termux-agent/inbox/` with one of these commands:

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
ROOT_CHECK
INSTALL_LATEST_APK_ROOT
DOWNLOAD_AND_INSTALL_APK_ROOT
COLLECT_SAFE_LOGS
COLLECT_LOGCAT
DOCTOR
RUN_ALL_CHECKS
```

Example task file:

```text
SERVER_CHECK
```

## Log collection

Safe logs:

```text
COLLECT_SAFE_LOGS
```

Full Android logcat snapshot:

```text
COLLECT_LOGCAT
```

Warning: logcat can include private information from device/app logs. Use only when needed.

## Security rules

- Do not share SSH passwords, private keys, or GitHub tokens.
- This agent is restricted to allowlisted commands.
- Root install is limited to APK install tasks only.
- It should run inside your project folder only.
- Do not expose your phone to the public internet.
- Keep ask-before-run mode enabled unless you understand the risk.

## Stop the agent

Press:

```text
CTRL + C
```
