#!/usr/bin/env bash

set -e

echo "Running server check..."
cd "$(dirname "$0")/../server"
npm install
npm run check

if command -v flutter >/dev/null 2>&1; then
  echo "Running Flutter dependency check..."
  cd ../flutter_app
  flutter create . --platforms=android
  flutter pub get
  flutter build apk --debug
else
  echo "Flutter not installed locally. Skipping Flutter build."
fi

echo "All checks completed."
