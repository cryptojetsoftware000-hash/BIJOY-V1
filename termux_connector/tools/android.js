const fs = require('fs');
const path = require('path');
const { ROOT, DOWNLOADS, ensureDir, run, runShell, validateUrl, jsonOk } = require('./common');

async function build_apk(args = {}) {
  const project = String(args.project || 'notepad');
  if (project === 'notepad') {
    return jsonOk({ result: await run('gradle', [':app:assembleDebug'], { cwd: 'android_notepad', timeout: 600000 }) });
  }
  if (project === 'flutter') {
    return jsonOk({ result: await runShell('flutter create . --platforms=android && flutter pub get && flutter build apk --debug', { cwd: 'flutter_app', timeout: 900000 }) });
  }
  throw new Error('Unknown project. Use notepad or flutter');
}

async function download_apk(args = {}) {
  const url = validateUrl(args.url || 'https://github.com/cryptojetsoftware000-hash/BIJOY-V1/releases/download/notepad-latest/bijoy-notepad.apk');
  const name = String(args.name || 'downloaded.apk').replace(/[^A-Za-z0-9._-]/g, '');
  if (!name.endsWith('.apk')) throw new Error('APK name must end with .apk');
  ensureDir(DOWNLOADS);
  const target = path.join(DOWNLOADS, name);
  const result = await runShell(`curl -L --fail ${JSON.stringify(url)} -o ${JSON.stringify(target)} && ls -lh ${JSON.stringify(target)}`, { timeout: 300000 });
  return jsonOk({ path: path.relative(ROOT, target), result });
}

module.exports = { build_apk, download_apk };
