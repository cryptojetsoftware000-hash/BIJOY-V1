const { execFile } = require('child_process');
const path = require('path');
const fs = require('fs');

const ROOT = path.resolve(__dirname, '..', '..');
const DOWNLOADS = path.join(ROOT, 'termux-agent', 'downloads');

function ensureDir(dir) {
  fs.mkdirSync(dir, { recursive: true });
}

function run(command, args = [], options = {}) {
  const cwd = options.cwd ? safePath(options.cwd) : ROOT;
  const timeout = Number(options.timeout || 120000);
  return new Promise((resolve) => {
    execFile(command, args, { cwd, timeout, maxBuffer: 1024 * 1024 * 5 }, (error, stdout, stderr) => {
      resolve({
        ok: !error,
        code: error && typeof error.code === 'number' ? error.code : 0,
        stdout: String(stdout || ''),
        stderr: String(stderr || ''),
        command,
        args,
        cwd
      });
    });
  });
}

function runShell(script, options = {}) {
  return run('bash', ['-lc', script], options);
}

function safePath(input = '.') {
  const resolved = path.resolve(ROOT, input);
  if (!resolved.startsWith(ROOT)) {
    throw new Error('Path outside project root is blocked');
  }
  return resolved;
}

function validatePackage(pkg) {
  const value = String(pkg || '').trim();
  if (!/^[A-Za-z0-9_]+(\.[A-Za-z0-9_]+)+$/.test(value)) {
    throw new Error('Invalid Android package name');
  }
  return value;
}

function validateUrl(url) {
  const value = String(url || '').trim();
  const u = new URL(value);
  if (!['https:'].includes(u.protocol)) throw new Error('Only HTTPS URLs are allowed');
  return value;
}

function jsonOk(data) {
  return { ok: true, ...data };
}

function jsonErr(error) {
  return { ok: false, error: error && error.message ? error.message : String(error) };
}

module.exports = {
  ROOT,
  DOWNLOADS,
  ensureDir,
  run,
  runShell,
  safePath,
  validatePackage,
  validateUrl,
  jsonOk,
  jsonErr
};
