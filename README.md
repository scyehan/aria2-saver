# aria2-saver

A lightweight macOS menu bar app that acts as a browser proxy for aria2. Routes URLs from [BrowserFairy](https://www.nickyui.com/BrowserFairy) to remote aria2 backends via JSON-RPC, with download progress tracking, path history, and SMB file opening.

[中文说明](docs/README_zh.md)

## Features

- Registers as a browser, works with BrowserFairy to intercept download URLs
- Sends downloads to remote aria2 servers via JSON-RPC
- Multiple aria2 backend support with per-backend configuration
- Real-time download progress in the menu bar
- Download history with per-backend tabs
- Path auto-completion from history (10 entries per backend)
- Open completed files via SMB in Finder
- Download from clipboard via menu or global hotkey (`⌘⇧D`)
- YAML-based configuration
- No Dock icon, lives in the menu bar

## Requirements

- macOS 14 (Sonoma) or later
- Swift 6.0+ toolchain
- A running [aria2](https://aria2.github.io/) instance with JSON-RPC enabled

## Build

```bash
git clone https://github.com/user/aria2-saver.git
cd aria2-saver
make app
```

The `.app` bundle will be at `.build/arm64-apple-macosx/debug/aria2-saver.app`.

To install to `/Applications`:

```bash
make install
```

## Configuration

Create `~/.config/aria2-saver/config.yaml` (auto-created on first launch):

```yaml
backends:
  - id: homelab
    host: 192.168.1.100
    port: 6800
    useTLS: false
    secret: "your_rpc_secret"
    defaultDir: /data/downloads
    sambaPrefix: /share        # optional, SMB path prefix
    sambaHost: 192.168.1.200   # optional, defaults to host

defaultBackendId: homelab
```

| Field | Required | Description |
|-------|----------|-------------|
| `id` | yes | Unique identifier for the backend |
| `host` | yes | aria2 RPC server address |
| `port` | no | RPC port (default: 6800) |
| `useTLS` | no | Use HTTPS for RPC (default: false) |
| `secret` | no | aria2 RPC secret token |
| `defaultDir` | no | Default download directory |
| `sambaPrefix` | no | SMB path prefix for opening files in Finder |
| `sambaHost` | no | SMB server address, defaults to `host` |

## Usage

1. Launch `aria2-saver` — an icon appears in the menu bar
2. Set it as a browser target in [BrowserFairy](https://www.nickyui.com/BrowserFairy)
3. When a URL is routed to aria2-saver, a dialog appears to select the backend and save path
4. Click "Download" to submit the task to aria2
5. Monitor progress from the menu bar; click "Show Downloads..." for the full list
6. Completed files can be opened via SMB directly from the download list

You can also copy a URL and press `⌘⇧D` (or click "Download from Clipboard" in the menu) to start a download without going through a browser.

## Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| `⌘⇧D` | Download URL from clipboard |

## License

MIT
