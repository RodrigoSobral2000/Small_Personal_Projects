# SwiftBar Custom Plugins

A collection of [SwiftBar](https://swiftbar.app/) plugins for managing SSH connections and network configurations. These plugins provide a convenient menu bar interface to control SSH tunnels and proxy settings from macOS.

## Projects

### 1. CERN SSH Proxy
A plugin for managing an SSH SOCKS tunnel to CERN infrastructure.

**What it does:**
- Displays the status of the SSH tunnel and the macOS SOCKS proxy
- Provides menu options to connect/disconnect the tunnel and enable/disable the proxy
- Authenticates with your existing SSH key (no password or 2FA prompt required)
- Runs the tunnel as a managed background `ssh` process (ControlMaster socket), so it survives after the menu closes
- Automatically manages the macOS SOCKS proxy for the configured network service

**Status Indicators:**
- Main icon: 🟢 (both SSH and Proxy enabled) or 🔴 (at least one is disabled)
- SSH status: 👍🏻 (tunnel running) or 👎🏿 (disconnected)
- Proxy status: 👍🏻 (proxy enabled) or 👎🏿 (proxy disabled)

**Dependencies:**
- bash
- ssh

---

### 2. RaspberryPi SSH Connector
A simple plugin for managing SSH connections to a Raspberry Pi or other remote host.

**What it does:**
- Displays connection status to a remote SSH host (Raspberry Pi)
- Provides menu options to quickly connect/disconnect via SSH
- Uses SSH key-based authentication for secure access
- Shows connection status: 🟢 (connected) or 🔴 (disconnected)

**Dependencies:**
- bash
- ssh

---

## Configuration

### Environment Setup

Both plugins read environment variables from a `.env` file in their script directory. Copy the `.env.example` template and edit it.

#### `.env.example` Template

```bash
# scripts/cern/.env

PROXY_PORT=          # Local port for the SOCKS proxy (e.g., 6789)
SSH_HOST=            # SSH host for the tunnel (e.g., lxtunnel)
NETWORK_SERVICE=     # macOS network service to configure (e.g., Wi-Fi)

# scripts/raspi/.env

SSH_KEY_PATH=        # Full path to SSH private key (e.g., ~/.ssh/id_rsa)
SSH_USER=            # SSH username for Raspberry Pi
SSH_HOST=            # Raspberry Pi hostname or IP address
```

### Setup Instructions

1. **Create environment files:**
   ```bash
   # For CERN plugin
   cp .env.example scripts/cern/.env

   # For RaspberryPi plugin
   cp .env.example scripts/raspi/.env
   ```

2. **Edit the `.env` files with your configuration:**
   - For **CERN**: set the proxy port, SSH host, and network service name
   - For **RaspberryPi**: set the SSH key path, username, and host address

3. **Ensure your SSH key is authorized for the CERN host:**
   The CERN plugin logs in with your SSH key, so no password or 2FA prompt is
   needed. Confirm it works non-interactively:
   ```bash
   ssh -o BatchMode=yes lxtunnel 'echo ok'
   ```
   If this fails, add your public key to the host (or use `ssh-copy-id`).

4. **Add plugins to SwiftBar:**
   - Open SwiftBar
   - Click the SwiftBar icon → "Open Plugins Folder"
   - Copy `cern.1s.sh` and/or `raspi.1s.sh` to the plugins folder
   - Refresh SwiftBar (SwiftBar menu → "Refresh")

---

## Expected Results

### CERN SSH Proxy Plugin

**On First Launch:**
- Menu bar shows 🔴 CERN (disconnected)
- Dropdown menu displays `SSH: 👎🏿 Proxy: 👎🏿` and a `Connect All` button

**After Connecting:**
- Menu bar shows 🟢 CERN (fully connected)
- SOCKS proxy is automatically enabled on the configured network service
- The SSH tunnel runs in the background via a ControlMaster socket
- Dropdown menu now displays `SSH: 👍🏻 Proxy: 👍🏻`, `Disconnect All`, and proxy toggle options

**How the tunnel is managed:**
- The tunnel is a background `ssh -N -D <port>` process with its own ControlMaster socket at `~/.ssh/cern-proxy.sock`
- Status is checked with `ssh -S <socket> -O check`
- Disconnect is done with `ssh -S <socket> -O exit`, then the proxy is turned off
- `ServerAliveInterval`/`ServerAliveCountMax` keep the connection healthy

### RaspberryPi SSH Connector Plugin

**On First Launch:**
- Menu bar shows 🔴 RASPI (disconnected)
- Dropdown menu displays `Status: Disconnected` and a `Connect` button (opens a terminal with the SSH session)

**After Connecting:**
- Menu bar shows 🟢 RASPI (connected)
- Terminal window opens with active SSH session
- Dropdown menu now displays `Status: Connected` and a `Disconnect` button

**Auto-refresh:**
- Plugin updates every 1 second (`1s` in filename)
- Status automatically reflects current connection state

---

## Usage

### CERN Plugin
- **Connect**: Click "Connect All" to establish the SSH tunnel and enable the proxy
- **Disconnect**: Click "Disconnect All" to stop the tunnel and disable the proxy
- **Toggle Proxy**: Use "Connect Proxy" / "Disconnect Proxy" to manage the proxy independently

### RaspberryPi Plugin
- **Connect**: Click "Connect" to open an SSH terminal session
- **Disconnect**: Click "Disconnect" to close the connection

---

## Troubleshooting

### "Error: .env file not found"
- Ensure `.env` exists in the correct script directory
- Check file permissions: `ls -la scripts/cern/.env`

### SSH Connection Fails
- Verify the host is reachable: `ssh -o BatchMode=yes <SSH_HOST> 'echo ok'`
- Ensure your SSH key is authorized on the host and has correct permissions: `chmod 600 ~/.ssh/<your_key>`
- Review the plugin log: `tail -20 ~/.cern-proxy.log`

### Tunnel won't start ("Address already in use")
- Something is already listening on `PROXY_PORT`. Find it with `lsof -nP -iTCP:<PROXY_PORT> -sTCP:LISTEN`
- A stale socket can also block startup; remove it with `rm -f ~/.ssh/cern-proxy.sock` and click "Connect All" again

### Proxy stays enabled after a crash
- Click "Disconnect Proxy", or run `networksetup -setsocksfirewallproxystate "<NETWORK_SERVICE>" off`

---

## File Structure

```
SwiftBarPlugins/
├── README.md                          # This file
├── .env.example                       # Environment template
├── .swiftbarignore                    # SwiftBar ignore rules
├── cern.1s.sh                         # CERN plugin (refreshes every 1 second)
├── raspi.1s.sh                        # RaspberryPi plugin (refreshes every 1 second)
└── scripts/
    ├── source_env.sh                  # Shared environment loader
    ├── cern/
    │   ├── .env                       # CERN configuration
    │   ├── connect.sh                 # Start the SSH tunnel + enable proxy
    │   ├── disconnect.sh              # Stop the SSH tunnel + disable proxy
    │   ├── enableproxy.sh             # macOS proxy enable
    │   └── disableproxy.sh            # macOS proxy disable
    └── raspi/
        ├── .env                       # RaspberryPi configuration
        ├── connect.sh                 # SSH connection script
        └── disconnect.sh              # SSH disconnection script
```
