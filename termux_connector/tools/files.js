const fs = require('fs');
const path = require('path');
const { ROOT, safePath, jsonOk } = require('./common');

async function list_files(args = {}) {
  const start = safePath(args.path || '.');
  const maxDepth = Number(args.maxDepth || 3);
  const results = [];

  function walk(dir, depth) {
    if (depth > maxDepth) return;
    for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
      if (entry.name === '.git' || entry.name === 'node_modules' || entry.name === 'build') continue;
      const full = path.join(dir, entry.name);
      const rel = path.relative(ROOT, full);
      results.push({ path: rel, type: entry.isDirectory() ? 'dir' : 'file' });
      if (entry.isDirectory()) walk(full, depth + 1);
    }
  }

  walk(start, 0);
  return jsonOk({ files: results });
}

async function read_file(args = {}) {
  const file = safePath(args.path);
  const stat = fs.statSync(file);
  if (!stat.isFile()) throw new Error('Not a file');
  if (stat.size > 1024 * 1024) throw new Error('File too large to read via connector');
  return jsonOk({ path: path.relative(ROOT, file), content: fs.readFileSync(file, 'utf8') });
}

async function write_file(args = {}) {
  const file = safePath(args.path);
  const content = String(args.content ?? '');
  if (Buffer.byteLength(content, 'utf8') > 1024 * 1024) throw new Error('Content too large');
  fs.mkdirSync(path.dirname(file), { recursive: true });
  fs.writeFileSync(file, content, 'utf8');
  return jsonOk({ path: path.relative(ROOT, file), bytes: Buffer.byteLength(content, 'utf8') });
}

module.exports = { list_files, read_file, write_file };
