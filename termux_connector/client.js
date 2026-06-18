const http = require('http');
const readline = require('readline');
const fs = require('fs');
const path = require('path');

const HOST = process.env.TERMUX_CONNECTOR_HOST || '127.0.0.1';
const PORT = Number(process.env.TERMUX_CONNECTOR_PORT || 8787);
const TOKEN = process.env.TERMUX_CONNECTOR_TOKEN || fs.readFileSync(path.join(__dirname, '.token'), 'utf8').trim();

const rl = readline.createInterface({ input: process.stdin, output: process.stdout });
function ask(q) { return new Promise(r => rl.question(q, r)); }

function callTool(tool, args) {
  return new Promise((resolve, reject) => {
    const body = JSON.stringify({ tool, args });
    const req = http.request({
      host: HOST,
      port: PORT,
      path: '/tool',
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${TOKEN}`,
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(body)
      }
    }, res => {
      let data = '';
      res.on('data', c => data += c);
      res.on('end', () => {
        try { resolve(JSON.parse(data)); }
        catch (e) { resolve({ ok: false, raw: data }); }
      });
    });
    req.on('error', reject);
    req.write(body);
    req.end();
  });
}

const shortcuts = {
  files: ['list_files', { path: '.', maxDepth: 2 }],
  status: ['git_status', {}],
  pull: ['git_pull', {}],
  info: ['device_info', {}],
  logs: ['collect_logcat', { lines: 500 }],
  notepad_install: ['download_apk', { url: 'https://github.com/cryptojetsoftware000-hash/BIJOY-V1/releases/download/notepad-latest/bijoy-notepad.apk', name: 'bijoy-notepad.apk' }],
  notepad_root_install: ['install_apk_root', { name: 'bijoy-notepad.apk' }],
  notepad_start: ['start_app', { package: 'com.bijoy.notepad' }],
  notepad_crash: ['collect_crash_logs', { package: 'com.bijoy.notepad' }]
};

async function main() {
  console.log('BIJOY Termux Connector CLI');
  console.log('Shortcuts:', Object.keys(shortcuts).join(', '));
  console.log('Custom JSON: {"tool":"list_files","args":{"path":".","maxDepth":2}}');
  console.log('Type exit to quit.');

  while (true) {
    const line = (await ask('\nconnector> ')).trim();
    if (!line) continue;
    if (line === 'exit' || line === 'quit') break;

    let tool, args;
    if (shortcuts[line]) {
      [tool, args] = shortcuts[line];
    } else {
      try {
        const parsed = JSON.parse(line);
        tool = parsed.tool;
        args = parsed.args || {};
      } catch (e) {
        console.log('Unknown command. Use a shortcut or JSON tool call.');
        continue;
      }
    }

    const res = await callTool(tool, args);
    console.log(JSON.stringify(res, null, 2).slice(0, 12000));
  }
  rl.close();
}

main().catch(e => {
  console.error(e.message || e);
  process.exit(1);
});
