#!/usr/bin/env bash

set -e

cd "$(dirname "$0")/../flutter_app"

flutter create . --platforms=android
flutter pub get
flutter build apk --debug

echo "APK created at: flutter_app/build/app/outputs/flutter-apk/app-debug.apk"
