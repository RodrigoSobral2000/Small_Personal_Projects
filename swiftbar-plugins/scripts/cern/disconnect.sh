#!/bin/bash
set -euo pipefail

export PATH="/usr/bin:/bin:/usr/sbin:/sbin:/opt/homebrew/bin:/usr/local/bin"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN=cern source "$SCRIPT_DIR/../source_env.sh"

CONTROL_SOCKET="${CONTROL_SOCKET:-$HOME/.ssh/cern-proxy.sock}"

# Turn the proxy off first so traffic stops flowing through a dead tunnel
"$SCRIPT_DIR/disableproxy.sh" || true

if ssh -S "$CONTROL_SOCKET" -O check "$SSH_HOST" >/dev/null 2>&1; then
    ssh -S "$CONTROL_SOCKET" -O exit "$SSH_HOST" >/dev/null 2>&1 || true
fi
rm -f "$CONTROL_SOCKET"

# Fallback: kill anything still listening on the SOCKS port
PIDS="$(lsof -nP -tiTCP:"$PROXY_PORT" -sTCP:LISTEN 2>/dev/null || true)"
if [ -n "$PIDS" ]; then
    echo "$PIDS" | xargs kill 2>/dev/null || true
fi
