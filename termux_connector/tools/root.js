const path = require('path');
const { ROOT, DOWNLOADS, runShell, validatePackage, safePath, jsonOk } = require('./common');

function apkPath(nameOrPath) {
  const value = String(nameOrPath || 'downloaded.apk');
  const p = value.includes('/') ? safePath(value) : path.join(DOWNLOADS, value.replace(/[^A-Za-z0-9._-]/g, ''));
  if (!p.endsWith('.apk')) throw new Error('APK path must end with .apk');
  return p;
}

async function install_apk_root(args = {}) {
  const apk = apkPath(args.path || args.name || 'downloaded.apk');
  const tmp = `/data/local/tmp/${path.basename(apk)}`;
  const script = `su -c "cp '${apk}' '${tmp}' && chmod 644 '${tmp}' && pm install -r '${tmp}'"`;
  return jsonOk({ result: await runShell(script, { timeout: 300000 }) });
}

async function uninstall_app_root(args = {}) {
  const pkg = validatePackage(args.package);
  return jsonOk({ result: await runShell(`su -c "pm uninstall '${pkg}' || pm uninstall --user 0 '${pkg}'"`) });
}

async function clear_app_data_root(args = {}) {
  const pkg = validatePackage(args.package);
  return jsonOk({ result: await runShell(`su -c "pm clear '${pkg}'"`) });
}

async function start_app(args = {}) {
  const pkg = validatePackage(args.package);
  return jsonOk({ result: await runShell(`su -c "monkey -p '${pkg}' -c android.intent.category.LAUNCHER 1"`) });
}

async function stop_app(args = {}) {
  const pkg = validatePackage(args.package);
  return jsonOk({ result: await runShell(`su -c "am force-stop '${pkg}'"`) });
}

async function restart_app(args = {}) {
  const pkg = validatePackage(args.package);
  const result = await runShell(`su -c "am force-stop '${pkg}'"; sleep 1; su -c "monkey -p '${pkg}' -c android.intent.category.LAUNCHER 1"`);
  return jsonOk({ result });
}

module.exports = {
  install_apk_root,
  uninstall_app_root,
  clear_app_data_root,
  start_app,
  stop_app,
  restart_app
};
