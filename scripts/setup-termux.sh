#!/data/data/com.termux/files/usr/bin/bash

set -e

echo "Updating Termux packages..."
pkg update -y
pkg upgrade -y

echo "Installing required tools..."
pkg install -y git nodejs nano curl

echo "Checking versions..."
node -v
npm -v
git --version

echo "Setup complete."
echo "Next: cd BIJOY-V1/server && npm install && npm start"
