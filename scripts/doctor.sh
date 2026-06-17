#!/usr/bin/env bash

set +e

echo "=============================="
echo "BIJOY-V1 Doctor"
echo "=============================="

echo "Git:"
git --version

echo "Node:"
node -v

echo "NPM:"
npm -v

echo "Flutter:"
flutter --version

echo "Java:"
java -version

echo "Server syntax check:"
cd "$(dirname "$0")/../server" || exit 1
npm install
npm run check

echo "Doctor finished."
