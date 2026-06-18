const path = require('path');
const { runShell, validatePackage, jsonOk } = require('./common');

async function collect_logcat(args = {}) {
  const lines = Math.min(Math.max(Number(args.lines || 500), 50), 2000);
  return jsonOk({ result: await runShell(`logcat -d -t ${lines} 2>&1 || true`) });
}

async function collect_crash_logs(args = {}) {
  const pkg = args.package ? validatePackage(args.package) : '';
  const filter = pkg ? `${pkg}|AndroidRuntime|FATAL EXCEPTION|crash|fatal|exception` : 'AndroidRuntime|FATAL EXCEPTION|crash|fatal|exception';
  return jsonOk({ result: await runShell(`logcat -d -t 1500 2>&1 | grep -i -E ${JSON.stringify(filter)} | tail -n 700 || true`) });
}

async function take_screenshot() {
  const file = `/sdcard/Download/termux-connector-screenshot-${Date.now()}.png`;
  return jsonOk({ path: file, result: await runShell(`screencap -p ${JSON.stringify(file)} && ls -lh ${JSON.stringify(file)}`) });
}

async function screen_record(args = {}) {
  let duration = Math.min(Math.max(Number(args.duration || 10), 1), 60);
  const file = `/sdcard/Download/termux-connector-record-${Date.now()}.mp4`;
  const result = await runShell(`timeout ${duration + 3} screenrecord --time-limit ${duration} ${JSON.stringify(file)} 2>&1 || true; ls -lh ${JSON.stringify(file)} 2>/dev/null || true`, { timeout: (duration + 10) * 1000 });
  return jsonOk({ path: file, result });
}

async function device_info() {
  const script = `
    echo '=== device ==='
    getprop ro.product.manufacturer
    getprop ro.product.model
    getprop ro.build.version.release
    getprop ro.build.version.sdk
    echo '=== root ==='
    su -c id 2>/dev/null || true
    echo '=== storage ==='
    df -h | head -n 40
    echo '=== battery ==='
    dumpsys battery | head -n 80
  `;
  return jsonOk({ result: await runShell(script) });
}

module.exports = {
  collect_logcat,
  collect_crash_logs,
  take_screenshot,
  screen_record,
  device_info
};
