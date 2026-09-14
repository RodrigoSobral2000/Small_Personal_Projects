# SwiftBar Custom Plugins

Two [SwiftBar](https://swiftbar.app/) menu bar plugins for SSH and proxy management on macOS.

| Plugin | Purpose |
| --- | --- |
| `cern.1s.sh` | Starts an SSH SOCKS tunnel to a CERN host and routes macOS traffic through it |
| `raspi.1s.sh` | Opens/closes an interactive SSH session to a Raspberry Pi |

Both refresh every second (`.1s.` in the filename) and authenticate with your existing SSH keys.

---

## CERN SSH Proxy

**What it does**
- Opens a background SOCKS tunnel with `ssh -N -D`, using your SSH key (no password or 2FA prompt).
- Enables/disables the macOS SOCKS proxy for the configured network service.
- Menu bar shows 🟢 when both the tunnel and proxy are up, 🔴 otherwise.
- Menu: `Connect All`, `Disconnect All`, and a proxy-only toggle.

**Configuration** — `scripts/cern/.env`

```bash
PROXY_PORT=6789        # local SOCKS port
SSH_HOST=lxtunnel      # SSH host (resolved via ~/.ssh/config)
NETWORK_SERVICE=Wi-Fi  # macOS network service to configure
```

**Notes**
- Run `ssh -o BatchMode=yes "$SSH_HOST" 'echo ok'` first to confirm key-based auth works.
- The tunnel is managed through a ControlMaster socket at `~/.ssh/cern-proxy.sock`; status is checked with `ssh -O check` and closed with `ssh -O exit`.
- Actions are logged to `~/.cern-proxy.log`; errors also raise a notification.

---

## RaspberryPi SSH Connector

**What it does**
- Shows 🟢/🔴 depending on whether an `ssh` session to the host is running.
- `Connect` opens an interactive SSH session in Terminal; `Disconnect` closes it.

**Configuration** — `scripts/raspi/.env`

```bash
SSH_KEY_PATH=$HOME/.ssh/id_ed25519_raspi  # private key for the host
SSH_USER=raspi                            # login user
SSH_HOST=raspi                            # hostname or IP
```

---

## Setup

1. **Create the config files** (one per plugin):

   ```bash
   cp .env.example scripts/cern/.env
   cp .env.example scripts/raspi/.env
   ```

   Edit each file for the plugin you use.

2. **Secure your SSH keys:**

   ```bash
   chmod 600 ~/.ssh/<your_key>
   ```

3. **Point SwiftBar at this folder:** SwiftBar menu → *Open Plugins Folder* → select `swiftbar-plugins`, then refresh.

**Requirements:** `bash`, `ssh`. No other tools are needed.

---

## Don't break the helper scripts

`.swiftbarignore` excludes `scripts/*` and `scripts/*/*` so SwiftBar does **not** import the helper scripts (`connect.sh`, `enableproxy.sh`, ...) as plugins. If you add helper scripts at a deeper path, add a matching entry — SwiftBar's `*` does not cross `/` and `**` is not honored. Files at the top level (`*.1s.sh`) are the actual plugins.

---

## Troubleshooting

- **CERN tunnel won't start / port busy:** `lsof -nP -iTCP:6789 -sTCP:LISTEN`; remove a stale socket with `rm -f ~/.ssh/cern-proxy.sock`.
- **Proxy left on after a crash:** click `Disconnect Proxy`, or `networksetup -setsocksfirewallproxystate "Wi-Fi" off`.
- **SSH fails:** verify reachability and key permissions (see Setup), then check `~/.cern-proxy.log`.
- **"Error: ... is not set in .env":** copy `.env.example` and fill in the missing value.

---

## File Structure

```
swiftbar-plugins/
├── cern.1s.sh              # CERN plugin
├── raspi.1s.sh             # RaspberryPi plugin
├── .env.example            # Template for the per-plugin .env files
├── .swiftbarignore         # Keeps helper scripts from loading as plugins
└── scripts/
    ├── source_env.sh       # Loads and validates a plugin's .env
    ├── cern/               # connect/disconnect + proxy enable/disable
    └── raspi/              # connect/disconnect
```
