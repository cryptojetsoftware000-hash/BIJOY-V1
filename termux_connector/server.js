const http = require('http');
const fs = require('fs');
const path = require('path');
const crypto = require('crypto');

const files = require('./tools/files');
const git = require('./tools/git');
const android = require('./tools/android');
const root = require('./tools/root');
const logs = require('./tools/logs');
const { ROOT, ensureDir, jsonErr } = require('./tools/common');

const HOST = process.env.TERMUX_CONNECTOR_HOST || '127.0.0.1';
const PORT = Number(process.env.TERMUX_CONNECTOR_PORT || 8787);
const TOKEN_FILE = path.join(ROOT, 'termux_connector', '.token');

function getToken() {
  if (process.env.TERMUX_CONNECTOR_TOKEN) return process.env.TERMUX_CONNECTOR_TOKEN;
  if (!fs.existsSync(TOKEN_FILE)) {
    fs.writeFileSync(TOKEN_FILE, crypto.randomBytes(24).toString('hex'), { mode: 0o600 });
  }
  return fs.readFileSync(TOKEN_FILE, 'utf8').trim();
}

const TOKEN = getToken();

const tools = {
  read_file: files.read_file,
  write_file: files.write_file,
  list_files: files.list_files,
  git_pull: git.git_pull,
  git_push: git.git_push,
  git_status: git.git_status,
  build_apk: android.build_apk,
  download_apk: android.download_apk,
  install_apk_root: root.install_apk_root,
  uninstall_app_root: root.uninstall_app_root,
  clear_app_data_root: root.clear_app_data_root,
  start_app: root.start_app,
  stop_app: root.stop_app,
  restart_app: root.restart_app,
  collect_logcat: logs.collect_logcat,
  collect_crash_logs: logs.collect_crash_logs,
  take_screenshot: logs.take_screenshot,
  screen_record: logs.screen_record,
  device_info: logs.device_info
};

function send(res, status, body) {
  res.writeHead(status, { 'content-type': 'application/json; charset=utf-8' });
  res.end(JSON.stringify(body, null, 2));
}

function readBody(req) {
  return new Promise((resolve, reject) => {
    let data = '';
    req.on('data', chunk => {
      data += chunk;
      if (data.length > 1024 * 1024) {
        reject(new Error('Request too large'));
        req.destroy();
      }
    });
    req.on('end', () => resolve(data));
    req.on('error', reject);
  });
}

function authOk(req) {
  const header = req.headers.authorization || '';
  return header === `Bearer ${TOKEN}` || req.headers['x-termux-token'] === TOKEN;
}

const server = http.createServer(async (req, res) => {
  try {
    if (req.method === 'GET' && req.url === '/health') {
      return send(res, 200, { ok: true, host: HOST, port: PORT, tools: Object.keys(tools), repo: ROOT });
    }

    if (!authOk(req)) {
      return send(res, 401, { ok: false, error: 'Unauthorized. Use Authorization: Bearer <token>' });
    }

    if (req.method === 'GET' && req.url === '/tools') {
      return send(res, 200, { ok: true, tools: Object.keys(tools) });
    }

    if (req.method === 'POST' && req.url === '/tool') {
      const raw = await readBody(req);
      const payload = raw ? JSON.parse(raw) : {};
      const name = String(payload.tool || '');
      const args = payload.args || {};
      if (!tools[name]) return send(res, 404, { ok: false, error: `Unknown tool: ${name}` });
      const result = await tools[name](args);
      return send(res, 200, result);
    }

    return send(res, 404, { ok: false, error: 'Not found' });
  } catch (error) {
    return send(res, 500, jsonErr(error));
  }
});

server.listen(PORT, HOST, () => {
  console.log('========================================');
  console.log('BIJOY Termux Connector Server');
  console.log(`URL: http://${HOST}:${PORT}`);
  console.log(`Token: ${TOKEN}`);
  console.log('Health: GET /health');
  console.log('Tools: GET /tools');
  console.log('Run: POST /tool {"tool":"list_files","args":{}}');
  console.log('========================================');
});
