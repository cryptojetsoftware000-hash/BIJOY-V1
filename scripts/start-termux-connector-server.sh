#!/data/data/com.termux/files/usr/bin/bash

set -e
cd "$(dirname "$0")/.."

pkg install -y nodejs curl git >/dev/null 2>&1 || true
mkdir -p termux-agent/downloads

cd termux_connector
npm run check
npm start
