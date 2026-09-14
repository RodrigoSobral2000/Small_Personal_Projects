#!/bin/bash
# <bitbar.title>CERN SSH Proxy</bitbar.title>
# <bitbar.version>v2.0</bitbar.version>
# <bitbar.author>Rodrigo Sobral</bitbar.author>
# <bitbar.author.github>rodrigo-sobral</bitbar.author.github>
# <bitbar.desc>Connect and disconnect a CERN SOCKS proxy powered by an SSH tunnel.</bitbar.desc>
# <bitbar.dependencies>bash,ssh</bitbar.dependencies>

export PATH="/usr/bin:/bin:/usr/sbin:/sbin:/opt/homebrew/bin:/usr/local/bin"

PLUGIN="cern"
PWD_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_DIR="$PWD_DIR/scripts/$PLUGIN"

PLUGIN=$PLUGIN source "$PWD_DIR/scripts/source_env.sh"

CONTROL_SOCKET="${CONTROL_SOCKET:-$HOME/.ssh/cern-proxy.sock}"

# SSH tunnel status (our own ControlMaster)
if ssh -S "$CONTROL_SOCKET" -O check "$SSH_HOST" >/dev/null 2>&1; then
    status="👍🏻"
else
    status="👎🏿"
fi

# SOCKS proxy status
if networksetup -getsocksfirewallproxy "$NETWORK_SERVICE" 2>/dev/null | grep -q "Enabled: Yes"; then
    proxy_status="👍🏻"
else
    proxy_status="👎🏿"
fi

if [ "$status" == "👍🏻" ] && [ "$proxy_status" == "👍🏻" ]; then
    icon="🟢"
else
    icon="🔴"
fi

# --- Menu Bar Display ---
echo "$icon CERN"
echo "---"
# --- Labels Display ---
echo "SSH: $status Proxy: $proxy_status | color=gray"
echo "---"

# --- Options Display ---
if [ "$status" == "👎🏿" ] || [ "$proxy_status" == "👎🏿" ]; then
    echo "Connect All | bash='$SCRIPTS_DIR/connect.sh' terminal=false refresh=true"
fi

if [ "$status" == "👍🏻" ] || [ "$proxy_status" == "👍🏻" ]; then
    echo "Disconnect All | bash='$SCRIPTS_DIR/disconnect.sh' terminal=false refresh=true"
fi

if [ "$proxy_status" == "👎🏿" ] && [ "$status" == "👍🏻" ]; then
    echo "Connect Proxy | bash='$SCRIPTS_DIR/enableproxy.sh' terminal=false refresh=true"
elif [ "$proxy_status" == "👍🏻" ]; then
    echo "Disconnect Proxy | bash='$SCRIPTS_DIR/disableproxy.sh' terminal=false refresh=true"
fi
