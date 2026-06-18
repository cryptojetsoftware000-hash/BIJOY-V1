#!/data/data/com.termux/files/usr/bin/bash

set -e

echo "Installing BIJOY-V1 Bridge Pro dependencies..."
pkg update -y
pkg install -y git nodejs curl termux-api

mkdir -p termux-agent/inbox termux-agent/outbox termux-agent/done termux-agent/failed termux-agent/rejected termux-agent/state termux-agent/downloads

chmod +x scripts/termux-bridge-pro.sh || true
chmod +x scripts/termux-root-dev-tools.sh || true
chmod +x scripts/termux-connector-agent.sh || true

git config user.name >/dev/null 2>&1 || git config user.name "Termux Bridge Pro"
git config user.email >/dev/null 2>&1 || git config user.email "termux-agent@local"

echo "Bridge Pro installed."
echo "Run normal ask mode:"
echo "  bash scripts/termux-bridge-pro.sh"
echo "Run fast auto mode:"
echo "  AGENT_AUTO_RUN=yes AGENT_SLEEP_SECONDS=5 bash scripts/termux-bridge-pro.sh"
