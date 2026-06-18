# BIJOY Termux Connector Server

This is a local HTTP connector server for Termux.

It exposes safe dev tools over HTTP:

```text
read_file
write_file
list_files
git_pull
git_push
git_status
build_apk
download_apk
install_apk_root
uninstall_app_root
clear_app_data_root
start_app
stop_app
restart_app
collect_logcat
collect_crash_logs
take_screenshot
screen_record
device_info
```

## Start in Termux

```bash
cd BIJOY-V1
git pull
bash scripts/start-termux-connector-server.sh
```

Server default:

```text
Host: 127.0.0.1
Port: 8787
```

The server prints a token on start. Keep that token private.

## Test locally in Termux

Health:

```bash
curl http://127.0.0.1:8787/health
```

Tools:

```bash
curl -H "Authorization: Bearer YOUR_TOKEN" http://127.0.0.1:8787/tools
```

Run a tool:

```bash
curl -X POST http://127.0.0.1:8787/tool \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"tool":"list_files","args":{"path":".","maxDepth":2}}'
```

Read file:

```bash
curl -X POST http://127.0.0.1:8787/tool \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"tool":"read_file","args":{"path":"README.md"}}'
```

Write file:

```bash
curl -X POST http://127.0.0.1:8787/tool \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"tool":"write_file","args":{"path":"tmp/test.txt","content":"hello"}}'
```

Build notepad APK:

```bash
curl -X POST http://127.0.0.1:8787/tool \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"tool":"build_apk","args":{"project":"notepad"}}'
```

Download APK:

```bash
curl -X POST http://127.0.0.1:8787/tool \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"tool":"download_apk","args":{"url":"https://github.com/cryptojetsoftware000-hash/BIJOY-V1/releases/download/notepad-latest/bijoy-notepad.apk","name":"bijoy-notepad.apk"}}'
```

Install APK with root:

```bash
curl -X POST http://127.0.0.1:8787/tool \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"tool":"install_apk_root","args":{"name":"bijoy-notepad.apk"}}'
```

Start app:

```bash
curl -X POST http://127.0.0.1:8787/tool \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"tool":"start_app","args":{"package":"com.bijoy.notepad"}}'
```

Collect crash logs:

```bash
curl -X POST http://127.0.0.1:8787/tool \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"tool":"collect_crash_logs","args":{"package":"com.bijoy.notepad"}}'
```

## Expose to another device

By default this server binds to `127.0.0.1`, which means only Termux itself can access it.

For LAN testing, run:

```bash
TERMUX_CONNECTOR_HOST=0.0.0.0 bash scripts/start-termux-connector-server.sh
```

Then use your phone Wi-Fi IP and the same token.

Do not expose this server publicly without HTTPS/tunnel authentication.

## Difference from Codex

Codex CLI runs directly inside your terminal and can use that terminal as its execution environment. This server is a local tool API. It becomes Codex-like when an AI client or another connector can call its HTTP endpoints.
