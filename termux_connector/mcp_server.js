const http = require('http');
const fs = require('fs');
const path = require('path');
const readline = require('readline');

const HOST = process.env.TERMUX_CONNECTOR_HOST || '127.0.0.1';
const PORT = Number(process.env.TERMUX_CONNECTOR_PORT || 8787);
const TOKEN_FILE = path.join(__dirname, '.token');
const TOKEN = process.env.TERMUX_CONNECTOR_TOKEN || (fs.existsSync(TOKEN_FILE) ? fs.readFileSync(TOKEN_FILE, 'utf8').trim() : '');

const toolDefs = [
  { name: 'read_file', description: 'Read a UTF-8 file from the BIJOY-V1 project.', inputSchema: { type: 'object', properties: { path: { type: 'string' } }, required: ['path'] } },
  { name: 'write_file', description: 'Write a UTF-8 file inside the BIJOY-V1 project.', inputSchema: { type: 'object', properties: { path: { type: 'string' }, content: { type: 'string' } }, required: ['path', 'content'] } },
  { name: 'list_files', description: 'List files inside the BIJOY-V1 project.', inputSchema: { type: 'object', properties: { path: { type: 'string' }, maxDepth: { type: 'number' } } } },
  { name: 'git_pull', description: 'Pull latest changes with rebase/autostash.', inputSchema: { type: 'object', properties: {} } },
  { name: 'git_push', description: 'Commit and push local project changes.', inputSchema: { type: 'object', properties: { message: { type: 'string' } } } },
  { name: 'git_status', description: 'Show short git status.', inputSchema: { type: 'object', properties: {} } },
  { name: 'build_apk', description: 'Build Android APK. project can be notepad or flutter.', inputSchema: { type: 'object', properties: { project: { type: 'string', enum: ['notepad', 'flutter'] } } } },
  { name: 'download_apk', description: 'Download an APK to termux-agent/downloads.', inputSchema: { type: 'object', properties: { url: { type: 'string' }, name: { type: 'string' } }, required: ['url'] } },
  { name: 'install_apk_root', description: 'Install a downloaded APK using root pm install.', inputSchema: { type: 'object', properties: { name: { type: 'string' }, path: { type: 'string' } } } },
  { name: 'uninstall_app_root', description: 'Uninstall an Android app package using root.', inputSchema: { type: 'object', properties: { package: { type: 'string' } }, required: ['package'] } },
  { name: 'clear_app_data_root', description: 'Clear app data for an Android package using root.', inputSchema: { type: 'object', properties: { package: { type: 'string' } }, required: ['package'] } },
  { name: 'start_app', description: 'Start an Android app package.', inputSchema: { type: 'object', properties: { package: { type: 'string' } }, required: ['package'] } },
  { name: 'stop_app', description: 'Force-stop an Android app package.', inputSchema: { type: 'object', properties: { package: { type: 'string' } }, required: ['package'] } },
  { name: 'restart_app', description: 'Restart an Android app package.', inputSchema: { type: 'object', properties: { package: { type: 'string' } }, required: ['package'] } },
  { name: 'collect_logcat', description: 'Collect recent Android logcat output.', inputSchema: { type: 'object', properties: { lines: { type: 'number' } } } },
  { name: 'collect_crash_logs', description: 'Collect crash logs, optionally filtered by package.', inputSchema: { type: 'object', properties: { package: { type: 'string' } } } },
  { name: 'take_screenshot', description: 'Take a screenshot to /sdcard/Download.', inputSchema: { type: 'object', properties: {} } },
  { name: 'screen_record', description: 'Record screen to /sdcard/Download for up to 60 seconds.', inputSchema: { type: 'object', properties: { duration: { type: 'number' } } } },
  { name: 'device_info', description: 'Collect Android device/root/storage/battery info.', inputSchema: { type: 'object', properties: {} } }
];

function callConnector(tool, args) {
  return new Promise((resolve, reject) => {
    if (!TOKEN) return reject(new Error('Connector token missing. Start server first or set TERMUX_CONNECTOR_TOKEN.'));
    const body = JSON.stringify({ tool, args: args || {} });
    const req = http.request({
      host: HOST,
      port: PORT,
      path: '/tool',
      method: 'POST',
      headers: {
        Authorization: `Bearer ${TOKEN}`,
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(body)
      }
    }, res => {
      let data = '';
      res.on('data', c => data += c);
      res.on('end', () => {
        try { resolve(JSON.parse(data)); }
        catch { resolve({ ok: false, raw: data }); }
      });
    });
    req.on('error', reject);
    req.write(body);
    req.end();
  });
}

function send(id, result, error) {
  const msg = error ? { jsonrpc: '2.0', id, error } : { jsonrpc: '2.0', id, result };
  process.stdout.write(JSON.stringify(msg) + '\n');
}

async function handle(req) {
  const id = req.id ?? null;
  try {
    if (req.method === 'initialize') {
      return send(id, {
        protocolVersion: req.params?.protocolVersion || '2024-11-05',
        capabilities: { tools: {} },
        serverInfo: { name: 'bijoy-termux-mcp', version: '1.0.0' }
      });
    }

    if (req.method === 'notifications/initialized') return;

    if (req.method === 'tools/list') {
      return send(id, { tools: toolDefs });
    }

    if (req.method === 'tools/call') {
      const name = req.params?.name;
      const args = req.params?.arguments || {};
      if (!toolDefs.some(t => t.name === name)) {
        return send(id, null, { code: -32602, message: `Unknown tool: ${name}` });
      }
      const result = await callConnector(name, args);
      return send(id, {
        content: [{ type: 'text', text: JSON.stringify(result, null, 2) }],
        isError: !result.ok
      });
    }

    return send(id, null, { code: -32601, message: `Method not found: ${req.method}` });
  } catch (e) {
    return send(id, null, { code: -32000, message: e.message || String(e) });
  }
}

const rl = readline.createInterface({ input: process.stdin, crlfDelay: Infinity });
rl.on('line', line => {
  if (!line.trim()) return;
  try { handle(JSON.parse(line)); }
  catch (e) { send(null, null, { code: -32700, message: 'Parse error' }); }
});
