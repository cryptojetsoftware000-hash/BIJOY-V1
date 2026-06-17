# Developer Toolkit for BIJOY-V1

This repo is configured with the basic tools needed for Flutter + Node.js app development.

## What is already configured

- Flutter app folder: `flutter_app/`
- Node.js local server folder: `server/`
- Android APK build workflow: `.github/workflows/build-android-apk.yml`
- Server syntax check workflow: `.github/workflows/checks.yml`
- VS Code recommended extensions: `.vscode/extensions.json`
- VS Code workspace settings: `.vscode/settings.json`
- Dependabot updates: `.github/dependabot.yml`
- Termux setup script: `scripts/setup-termux.sh`
- Server start script: `scripts/start-server.sh`
- APK build notes: `docs/APK_BUILD_GUIDE.md`

## Tools you need locally

### Android / Termux

```bash
pkg update -y
pkg upgrade -y
pkg install -y git nodejs
```

### PC / Laptop

Install:

- Git
- Node.js
- Flutter SDK
- Android Studio or Android SDK
- VS Code

## Server run

```bash
cd server
npm install
npm start
```

## Flutter run

```bash
cd flutter_app
flutter create . --platforms=android
flutter pub get
flutter run
```

## APK build on GitHub

Go to:

```text
GitHub repo → Actions → Build Android APK → Run workflow
```

After success, download artifact:

```text
BIJOY-V1-debug-apk
```

Inside it you will find:

```text
app-debug.apk
```
