const { run, jsonOk } = require('./common');

async function git_pull() {
  const result = await run('git', ['pull', '--rebase', '--autostash']);
  return jsonOk({ result });
}

async function git_push(args = {}) {
  const message = String(args.message || 'Termux connector update');
  const add = await run('git', ['add', '.']);
  const commit = await run('git', ['commit', '-m', message]);
  const pull = await run('git', ['pull', '--rebase', '--autostash']);
  const push = await run('git', ['push']);
  return jsonOk({ add, commit, pull, push });
}

async function git_status() {
  const result = await run('git', ['status', '--short']);
  return jsonOk({ result });
}

module.exports = { git_pull, git_push, git_status };
