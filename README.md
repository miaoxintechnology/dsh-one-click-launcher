# DSH 一键启动脚本

DeepSeek Harness（DSH）的一键启动脚本，Windows 与 Linux 两版逻辑完全一致：

1. **检测安装**：找不到 `dsh` 时，用国内镜像 `https://registry.npmmirror.com` 全局安装 `@deepseek-ai/dsh@latest`。
2. **检查更新**：读取 `dsh --version` 与 npm 上的最新版本，按语义化版本比较；有新版本则更新，失败也不阻塞启动。
3. **自动选端口**：从 `3080` 开始逐个探测 `127.0.0.1` 的空闲端口（上限 3999），全部占用时回退为 `0`（由 DSH 自动分配）。
4. **启动**：执行 `dsh web --port <端口>`，由 DSH 自行打开默认浏览器（SSH 环境下会抑制）。

## 文件

| 文件 | 平台 | 说明 |
| --- | --- | --- |
| `一键启动DSH.sh` | Linux / macOS | Bash 脚本，LF 换行 |
| `一键启动DSH.cmd` | Windows | 批处理，CRLF 换行，双击即可运行 |

## 用法

### Linux

```bash
chmod +x 一键启动DSH.sh
./一键启动DSH.sh
```

### Windows

双击 `一键启动DSH.cmd`，或在命令行执行：

```bat
一键启动DSH.cmd
```

## 环境要求

- Node.js / npm（DSH 本身依赖；没有 node 时会跳过更新检查）
- Linux 下还需要 `bash`；桌面环境下的 `xdg-open` 用于打开浏览器（由 DSH 调用）
- Windows 下使用系统自带的 PowerShell 探测空闲端口

## 说明

- 全局 npm 目录不可写时，`npm install -g` 可能报 `EACCES`，需要修正 npm 全局前缀或以 `sudo` 运行。
- Linux 版的端口探测与版本比较使用 Node.js 完成，不依赖 PowerShell 或 npm 内置的 `semver` 模块，因此在各发行版上行为一致。
- Windows 版沿用 PowerShell 做端口探测、Node.js 做版本比较。
- 版本比较支持预发布号（`0.2.2-rc.1 < 0.2.2`）与 `v` 前缀。
- 仓库通过 `.gitattributes` 固定换行：`*.sh` 为 LF，`*.cmd` 为 CRLF。

## 退出码

| 退出码 | 含义 |
| --- | --- |
| `0` | 正常启动并退出（或已是最新版本后启动） |
| `1` | DSH 安装失败 |

## 许可证

[MIT](LICENSE)
