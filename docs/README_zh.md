# aria2-saver

一款轻量级 macOS 菜单栏工具，作为 aria2 的下载前端。配合 [BrowserFairy](https://www.nickyui.com/BrowserFairy) 将浏览器中的 URL 路由到远程 aria2 服务器下载。

## 功能

- 注册为浏览器，可被 BrowserFairy 识别并路由 URL
- 通过 JSON-RPC 将下载任务提交到远程 aria2
- 支持多个 aria2 后端，独立配置
- 菜单栏实时显示下载进度和速度
- 下载历史按后端分 Tab 展示
- 路径历史自动补全（每个后端保存 6 条）
- 下载完成后通过 SMB 在 Finder 中打开文件
- 从剪贴板读取 URL 下载，支持全局快捷键 `⌘⇧D`
- YAML 配置文件
- 仅驻留菜单栏，不显示 Dock 图标

## 系统要求

- macOS 14 (Sonoma) 或更高版本
- Swift 6.0+ 工具链（用于编译）
- 一个已启用 JSON-RPC 的 [aria2](https://aria2.github.io/) 实例

## 编译

```bash
git clone https://github.com/user/aria2-saver.git
cd aria2-saver
make app
```

生成的 `.app` 位于 `.build/arm64-apple-macosx/debug/aria2-saver.app`。

安装到 `/Applications`：

```bash
make install
```

## 配置

编辑 `~/.config/aria2-saver/config.yaml`（首次启动自动创建示例配置）：

```yaml
backends:
  - id: homelab
    host: 192.168.1.100
    port: 6800
    useTLS: false
    secret: "your_rpc_secret"
    defaultDir: /data/downloads
    sambaPrefix: /share        # 可选，SMB 路径前缀
    sambaHost: 192.168.1.200   # 可选，默认与 host 相同

defaultBackendId: homelab
```

| 字段 | 必填 | 说明 |
|------|------|------|
| `id` | 是 | 后端唯一标识 |
| `host` | 是 | aria2 RPC 服务器地址 |
| `port` | 否 | RPC 端口（默认 6800） |
| `useTLS` | 否 | 是否使用 HTTPS（默认 false） |
| `secret` | 否 | aria2 RPC 密钥 |
| `defaultDir` | 否 | 默认下载目录 |
| `sambaPrefix` | 否 | SMB 路径前缀，用于在 Finder 中打开文件 |
| `sambaHost` | 否 | SMB 服务器地址，不填则使用 `host` |

## 使用方法

1. 启动 `aria2-saver`，菜单栏出现图标
2. 在 [BrowserFairy](https://www.nickyui.com/BrowserFairy) 中将其设为目标浏览器
3. 当 URL 被路由到 aria2-saver 时，弹出对话框选择后端和保存路径
4. 点击「Download」提交下载任务
5. 菜单栏可查看下载进度，点击「Show Downloads...」查看完整列表
6. 下载完成的文件可直接从列表通过 SMB 在 Finder 中打开

也可以复制 URL 后按 `⌘⇧D`（或点击菜单中的「Download from Clipboard」）直接发起下载，无需通过浏览器。

## 快捷键

| 快捷键 | 功能 |
|--------|------|
| `⌘⇧D` | 从剪贴板读取 URL 下载 |

## 许可

MIT
