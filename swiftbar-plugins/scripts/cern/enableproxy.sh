#!/bin/bash
set -euo pipefail

export PATH="/usr/bin:/bin:/usr/sbin:/sbin:/opt/homebrew/bin:/usr/local/bin"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN=cern source "$SCRIPT_DIR/../source_env.sh"

networksetup -setsocksfirewallproxy "$NETWORK_SERVICE" 127.0.0.1 "$PROXY_PORT"
networksetup -setsocksfirewallproxystate "$NETWORK_SERVICE" on
