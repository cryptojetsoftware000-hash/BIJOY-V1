# Termux Connector Agent

This is a safe GitHub bridge for Termux.

It does not give anyone direct SSH access to your phone. Instead, it works like this:

1. A task file is added to `.termux-agent/inbox/` in GitHub.
2. The Termux agent running on your phone pulls the repo.
3. The agent asks you before running the task.
4. The agent runs only allowed commands.
5. The agent writes the output log to `.termux-agent/outbox/` and pushes it back to GitHub.

## One-time setup in Termux

```bash
pkg update -y
pkg upgrade -y
pkg install -y git nodejs
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

## Allowed task commands

Create a `.task` file in `.termux-agent/inbox/` with one of these commands:

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
DOCTOR
RUN_ALL_CHECKS
```

Example task file:

```text
SERVER_CHECK
```

## Security rules

- Do not share SSH passwords, private keys, or GitHub tokens.
- This agent is restricted to allowlisted commands.
- It should run inside your project folder only.
- Do not expose your phone to the public internet.
- Keep ask-before-run mode enabled unless you understand the risk.

## Stop the agent

Press:

```text
CTRL + C
```
