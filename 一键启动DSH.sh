#!/usr/bin/env bash
# DeepSeek Harness one-click launcher for Linux.
# Same logic as the Windows 一键启动DSH.cmd:
#   0) install DSH if missing   1) auto-update   2) pick a free port   3) start the Web GUI
# The Web GUI opens the default browser by itself (xdg-open); pass --no-open to disable that.
#
# Usage: chmod +x 一键启动DSH.sh && ./一键启动DSH.sh

# Domestic npm mirror for faster updates
NPM_REGISTRY="https://registry.npmmirror.com"

# Port search range: first free loopback port wins (same range as the Windows script)
PORT_SCAN_FIRST=3080
PORT_SCAN_LAST=4000

# Exit codes shared with the Windows script: 3 = latest is newer, 0 = up to date / not newer,
# 2 = unparsable version. Semver comparison stays in node so no npm-bundled module is needed.
SEMVER_COMPARE='
const VERSION_RE = /^v?(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)(?:-([0-9A-Za-z-]+(?:\.[0-9A-Za-z-]+)*))?(?:\+[0-9A-Za-z-]+(?:\.[0-9A-Za-z-]+)*)?$/;

function parseVersion(text) {
  if (typeof text !== "string") return null;
  const m = VERSION_RE.exec(text.trim());
  if (m === null) return null;
  const pre = m[4] === undefined ? [] : m[4].split(".");
  return { core: [Number(m[1]), Number(m[2]), Number(m[3])], pre };
}

function comparePre(a, b) {
  if (a.length === 0 || b.length === 0) {
    return a.length === b.length ? 0 : (a.length === 0 ? 1 : -1);
  }
  const n = Math.min(a.length, b.length);
  for (let i = 0; i < n; i += 1) {
    const x = a[i];
    const y = b[i];
    const xNumeric = /^\d+$/.test(x);
    const yNumeric = /^\d+$/.test(y);
    if (xNumeric && yNumeric) {
      const d = Number(x) - Number(y);
      if (d !== 0) return d < 0 ? -1 : 1;
    } else if (xNumeric) {
      return -1;
    } else if (yNumeric) {
      return 1;
    } else if (x !== y) {
      return x < y ? -1 : 1;
    }
  }
  return a.length === b.length ? 0 : (a.length < b.length ? -1 : 1);
}

const current = parseVersion(process.argv[1]);
const latest = parseVersion(process.argv[2]);
if (current === null || latest === null) process.exit(2);

let cmp = 0;
for (let i = 0; i < 3; i += 1) {
  if (latest.core[i] !== current.core[i]) {
    cmp = latest.core[i] > current.core[i] ? 1 : -1;
    break;
  }
}
if (cmp === 0) cmp = comparePre(latest.pre, current.pre);
process.exit(cmp > 0 ? 3 : 0);
'

# Binds loopback ports one by one until one accepts a listener; prints it or exits 1.
PORT_PROBE='
const net = require("net");

function isFree(port) {
  return new Promise((resolve) => {
    const server = net.createServer();
    server.once("error", () => resolve(false));
    server.listen(port, "127.0.0.1", () => server.close(() => resolve(true)));
  });
}

(async () => {
  for (let port = Number(process.argv[1]); port < Number(process.argv[2]); port += 1) {
    if (await isFree(port)) {
      console.log(port);
      return;
    }
  }
  process.exit(1);
})();
'

# Keep a double-clicked terminal window open; a piped/non-interactive run does not wait.
pause() {
    if [ -t 0 ]; then
        printf "\nPress Enter to exit..."
        read -r _
    fi
}

echo "============================================"
echo "   DeepSeek Harness  One-Click Launcher"
echo "============================================"
echo

# ============ Step 0: ensure DSH is installed ============
if ! command -v dsh >/dev/null 2>&1; then
    echo "[INFO] DSH not found. Installing DSH via mirror..."
    if ! npm install -g @deepseek-ai/dsh@latest --registry="$NPM_REGISTRY"; then
        echo "[ERROR] DSH install failed. Check your network and try again."
        echo "        (If npm reports EACCES, fix the global npm prefix or run this script with sudo.)"
        pause
        exit 1
    fi
    echo "[OK] DSH installed."
    hash -r 2>/dev/null || true
fi

# ============ Step 1: check for updates ============
CURRENT="$(dsh --version 2>/dev/null | head -n 1 | tr -d '\r')"
echo "Current version : $CURRENT"

LATEST="$(npm view @deepseek-ai/dsh version --registry="$NPM_REGISTRY" 2>/dev/null | head -n 1 | tr -d '\r')"

if [ -z "$LATEST" ]; then
    echo "[INFO] Could not get the latest version, possibly offline. Skipping update."
elif ! command -v node >/dev/null 2>&1; then
    echo "Latest version  : $LATEST"
    echo
    echo "[INFO] node not found. Skipping update check."
else
    echo "Latest version  : $LATEST"
    echo

    # 3=newer  0=up-to-date  2=bad version  other=compare failed
    node -e "$SEMVER_COMPARE" "$CURRENT" "$LATEST"
    RC=$?

    case "$RC" in
        3)
            echo "[UPDATE] New version found. Updating DSH via mirror..."
            echo
            if npm install -g @deepseek-ai/dsh@latest --registry="$NPM_REGISTRY"; then
                echo "[OK] Update complete."
                hash -r 2>/dev/null || true
                CURRENT="$(dsh --version 2>/dev/null | head -n 1 | tr -d '\r')"
                echo "Updated version : $CURRENT"
            else
                echo "[WARN] Update failed. Starting with current version."
            fi
            ;;
        0)
            echo "[OK] Already up to date."
            ;;
        2)
            echo "[INFO] Odd version string. Starting with current version."
            ;;
        *)
            echo "[INFO] Version compare failed, code $RC. Starting with current version."
            ;;
    esac
fi

# ============ Step 2: auto-detect a free port ============
PORT="$(node -e "$PORT_PROBE" "$PORT_SCAN_FIRST" "$PORT_SCAN_LAST" 2>/dev/null)"
if [ -z "$PORT" ]; then
    PORT=0
fi

echo
echo "Port : $PORT"
if [ "$PORT" = "0" ]; then
    echo "URL  : http://127.0.0.1 (port auto-assigned, see the URL printed by dsh web below)"
else
    echo "URL  : http://127.0.0.1:$PORT"
fi
echo "Opening the browser..."
echo

# ============ Step 3: launch ============
dsh web --port "$PORT"

echo
echo "Service exited."
pause
