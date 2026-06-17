#!/usr/bin/env bash

set -e

echo "Cleaning Node modules and Flutter build files..."
rm -rf server/node_modules
rm -rf flutter_app/build
rm -rf flutter_app/.dart_tool
rm -rf flutter_app/android/.gradle

echo "Clean complete."
