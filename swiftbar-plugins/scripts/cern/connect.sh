#!/bin/bash
set -euo pipefail

export PATH="/usr/bin:/bin:/usr/sbin:/sbin:/opt/homebrew/bin:/usr/local/bin"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN=cern source "$SCRIPT_DIR/../source_env.sh"

CONTROL_SOCKET="${CONTROL_SOCKET:-$HOME/.ssh/cern-proxy.sock}"
LOG_FILE="${LOG_FILE:-$HOME/.cern-proxy.log}"

log() {
    printf '%s %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >>"$LOG_FILE" 2>/dev/null || true
}

notify() {
    osascript -e "display notification \"$1\" with title \"CERN Proxy\"" >/dev/null 2>&1 || true
}

fail() {
    log "ERROR: $*"
    notify "$*"
    echo "Error: $*" >&2
    exit 1
}

mkdir -p "$(dirname "$CONTROL_SOCKET")"

# Already connected: just make sure the proxy points at the running tunnel
if ssh -S "$CONTROL_SOCKET" -O check "$SSH_HOST" >/dev/null 2>&1; then
    log "Tunnel already running"
    "$SCRIPT_DIR/enableproxy.sh"
    exit 0
fi

# Remove a stale socket left behind by a crashed master
rm -f "$CONTROL_SOCKET"

log "Starting tunnel to $SSH_HOST (SOCKS 127.0.0.1:$PROXY_PORT)"
if ! ssh -M -S "$CONTROL_SOCKET" -f -N -D "$PROXY_PORT" \
    -o ControlMaster=yes -o ControlPersist=no \
    -o ExitOnForwardFailure=yes \
    -o ServerAliveInterval=30 -o ServerAliveCountMax=3 -o TCPKeepAlive=yes \
    -o ConnectTimeout=15 -o LogLevel=ERROR \
    "$SSH_HOST" >>"$LOG_FILE" 2>&1; then
    rm -f "$CONTROL_SOCKET"
    fail "Failed to start SSH tunnel to $SSH_HOST (see $LOG_FILE)"
fi

# Confirm the master (and therefore the SOCKS forward) is up
for _ in 1 2 3 4 5; do
    if ssh -S "$CONTROL_SOCKET" -O check "$SSH_HOST" >/dev/null 2>&1; then
        break
    fi
    sleep 1
done

if ! ssh -S "$CONTROL_SOCKET" -O check "$SSH_HOST" >/dev/null 2>&1; then
    fail "SSH tunnel did not come up (see $LOG_FILE)"
fi

"$SCRIPT_DIR/enableproxy.sh"
log "Connected; proxy enabled on $NETWORK_SERVICE:$PROXY_PORT"
