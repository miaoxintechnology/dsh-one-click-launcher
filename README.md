# DSH 一键启动脚本（Linux）

DeepSeek Harness（DSH）的 Linux 一键启动脚本，逻辑与 Windows 版 `一键启动DSH.cmd` 完全对应。

## 做了什么

1. **检测安装**：找不到 `dsh` 时，用国内镜像 `https://registry.npmmirror.com` 全局安装 `@deepseek-ai/dsh@latest`。
2. **检查更新**：读取 `dsh --version` 与 npm 上的最新版本，按语义化版本比较；有新版本则更新，失败也不阻塞启动。
3. **自动选端口**：从 `3080` 开始逐个探测 `127.0.0.1` 的空闲端口（上限 3999），全部占用时回退为 `0`（由 DSH 自动分配）。
4. **启动**：执行 `dsh web --port <端口>`，由 DSH 自行打开默认浏览器（SSH 环境下会抑制）。

## 用法

```bash
chmod +x 一键启动DSH.sh
./一键启动DSH.sh
```

## 环境要求

- `bash`
- `npm` / `node`（DSH 本身依赖 Node.js；没有 node 时会跳过更新检查）
- Linux 桌面环境下的 `xdg-open`（由 DSH 调用，用于打开浏览器）

## 说明

- 全局 npm 目录不可写时，`npm install -g` 可能报 `EACCES`，需要修正 npm 全局前缀或以 `sudo` 运行。
- 端口探测与版本比较使用 Node.js 完成，不依赖 PowerShell 或 npm 内置的 `semver` 模块，因此在各发行版上行为一致。
- 版本比较支持预发布号（`0.2.2-rc.1 < 0.2.2`）与 `v` 前缀。
- 脚本为 LF 换行、UTF-8 无 BOM，可直接在 Linux 上运行。

## 退出码

| 退出码 | 含义 |
| --- | --- |
| `0` | 正常启动并退出（或已是最新版本后启动） |
| `1` | DSH 安装失败 |
