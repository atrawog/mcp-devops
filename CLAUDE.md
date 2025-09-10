# MCP DevOps Development Container

Arch Linux Wayland desktop development container with KRDC-compatible VNC access.

## Quick Reference

| Action | Method | Notes |
|--------|--------|-------|
| Start container | `just up` | Builds and starts with VNC on port 5900 |
| Connect VNC | KRDC → `localhost:5900` | No password required (default) |
| Open launcher | `Mod4+d` (Super+D) | Shows Terminal and Chrome only |
| Open terminal | `Mod4+Return` | Opens new foot terminal |
| Open Chrome | `Mod4+c` | Direct Chrome launch |
| Stop container | `just down` | Stops and removes container |

## Quick Start

```bash
# Build and run container with VNC on port 5900
just up

# Connect via VNC client to localhost:5900
# Password: mcp-devops (or set VNC_PASSWORD env var)

# Open app launcher (after connecting via VNC)
# Press Mod4+d (Super/Windows key + D)
```

## Architecture

### Stack
- **Base**: Arch Linux (latest)
- **Init**: s6-overlay for service management
- **Compositor**: Sway (Wayland) in headless mode with seat0 configuration
- **VNC**: wayvnc with seat configuration and cursor rendering
- **Browser**: Google Chrome (installed from AUR)
- **Launcher**: wofi (filtered to show only Terminal and Chrome)
- **Terminal**: foot (auto-starts on container launch)
- **Task Runner**: just
- **Default User**: jovian (UID/GID mapped from host)

### Directory Structure
```
mcp-devops/
├── config/
│   ├── s6/                 # S6 service definitions
│   │   ├── workspace-fix/   # Permission setup service
│   │   ├── sway/           # Sway compositor service
│   │   └── wayvnc/         # VNC server service
│   ├── sway/               # Sway window manager config
│   ├── wayvnc/             # VNC server config
│   ├── wofi/               # App launcher config and styles
│   ├── waybar/             # Taskbar config and styles
│   └── applications/       # Desktop entries (Terminal & Chrome only)
├── scripts/
│   ├── docker-entrypoint.sh # Container entrypoint
│   ├── launcher.sh         # Basic launcher script
│   └── launcher-strict.sh  # Filtered launcher (Terminal & Chrome only)
├── .devcontainer/
│   └── devcontainer.json   # VS Code Dev Container config
├── Dockerfile               # Container definition
├── Justfile                # Task automation
└── CLAUDE.md              # This file
```

## Configuration Files

### S6 Service Scripts
Services are managed by s6-overlay and start in this order:
1. **workspace-fix**: Sets up runtime directories and permissions
2. **sway**: Starts the Wayland compositor in headless mode
3. **wayvnc**: Starts VNC server once Wayland is ready

### Sway Configuration
- Configured for headless operation with HEADLESS-1 output
- Auto-launches only foot terminal on startup (Chrome available via launcher)
- Modern Tokyo Night color scheme
- Input device configuration for virtual pointer
- Seat0 configuration with xcursor theme
- Multiple mouse binding attempts for launcher (limited by VNC)
- Standard keybindings (Mod4+Enter for terminal, Mod4+d for launcher, etc.)

### WayVNC Configuration
- Listens on all interfaces (0.0.0.0:5900)
- Authentication disabled by default for development
- Uses seat0 for input device management
- Cursor rendering enabled for better visual feedback
- Creates virtual pointer device (wlr_virtual_pointer_v1)
- KRDC-compatible settings

## Just Commands

```bash
just --list                  # Show all available commands
just up                      # Build and start container
just down                    # Stop and remove container
just rebuild                 # Clean rebuild
just shell                   # Shell as root
just user-shell             # Shell as jovian
just logs                    # View container logs
just status                  # Check service status
just info                    # Show container info
just test-dev               # Test development environment
just test-vnc               # Test VNC connectivity
just check-workspace        # Check workspace permissions
just fix-permissions        # Fix workspace permissions
just clean                  # Remove container and image
```

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `VNC_PASSWORD` | `mcp-devops` | VNC password (if auth enabled) |
| `USER_UID` | Current user UID | Container user UID |
| `USER_GID` | Current user GID | Container user GID |
| `WLR_SEAT` | `seat0` | Wayland seat for input handling |
| `WLR_BACKENDS` | `headless` | Wayland backend type |
| `WAYLAND_DISPLAY` | `wayland-1` | Wayland display socket |

## VNC Access

### Connecting with KRDC
1. Open KRDC
2. Create new VNC connection to `localhost:5900`
3. No authentication required (default)
4. You'll see Sway desktop with terminal and Chrome

### Desktop Features
- **Auto-start**: Terminal (foot) launches automatically on container start
- **App Launcher**: Shows only Terminal and Chrome options (filtered wofi)
  - **Primary method**: Press `Mod4+d` (Super/Windows + D) - Most reliable
  - **Alternative**: `Alt+Right-click` or `Super+Right-click` may work
  - **Note**: Direct right-click doesn't work due to VNC/Wayland limitations
- **Keyboard Shortcuts**:
  - `Mod4+d`: Open app launcher (recommended method)
  - `Mod4+Return`: Open new terminal
  - `Mod4+c`: Open Chrome directly
  - `Mod4+Shift+q`: Close window
  - `Mod4+Shift+r`: Reload Sway config
  - `Mod4+Shift+e`: Exit Sway

### Connecting with other VNC clients
Any VNC client supporting the RFB protocol should work:
- TigerVNC: `vncviewer localhost:5900`
- RealVNC: Connect to `localhost:5900`
- macOS Screen Sharing: `vnc://localhost:5900`

## Development Features

### UID/GID Mapping
The container automatically maps your host user's UID/GID to the `jovian` user inside the container, ensuring proper file permissions for the workspace.

### Docker Socket Access

The container provides Docker access via socket mounting with automatic permission synchronization:

#### How it Works
1. **Automatic GID Sync**: On container startup, the `sync-docker-gid.sh` script runs
2. **Group Adjustment**: The Docker group GID in the container is updated to match the host socket
3. **User Membership**: The jovian user is added to the correct Docker group
4. **DevContainer Support**: VS Code DevContainers run the sync via `postStartCommand`

#### Usage
```bash
# After starting container, refresh group membership in existing shells
docker exec -u jovian <container> bash -c 'newgrp docker && docker ps'

# Or use a fresh shell session (groups already loaded)
docker exec -u jovian <container> su - jovian -c 'docker ps'

# Verify Docker permissions
just verify-docker
```

#### Troubleshooting Docker Access
- If Docker commands fail with "permission denied", run: `newgrp docker`
- New shell sessions automatically have correct permissions
- The sync script runs at container startup via the entrypoint
- Manual sync: `sudo /usr/local/bin/sync-docker-gid.sh`

### VS Code Dev Container
The `.devcontainer/devcontainer.json` follows the official [Dev Container specification](https://containers.dev/implementors/spec/) with proper user configuration:

#### User Configuration
- **remoteUser**: Set to `jovian` - the user VS Code runs as inside the container
- **updateRemoteUserUID**: Set to `true` - automatically syncs container user UID/GID with host user
- **No manual UID mapping needed**: The Dev Container handles UID/GID sync automatically

#### Key Features
- Compliant with Dev Container spec - no hardcoded UIDs or manual user mapping
- Automatic UID/GID synchronization via `updateRemoteUserUID`
- Simplified entrypoint that doesn't interfere with Dev Container features
- Pre-configured extensions for Docker, Kubernetes, Just, and Makefile support
- Lifecycle commands for automatic updates and workspace permission fixes

#### Usage with VS Code
1. Open the project folder in VS Code
2. Install the "Dev Containers" extension if not already installed
3. Click "Reopen in Container" when prompted, or use Command Palette: "Dev Containers: Reopen in Container"
4. VS Code will build and start the container with proper user permissions automatically
5. The workspace will be mounted at `/workspace` with correct ownership

### Workspace Persistence
The current directory is mounted at `/workspace` with automatic ownership management through Dev Container's `updateRemoteUserUID` feature.

## Known Limitations

### Mouse Input through VNC
- **Right-click binding limitation**: Direct right-click to open launcher doesn't work reliably through VNC
- **Cause**: VNC creates a virtual pointer device (`wlr_virtual_pointer_v1`) that doesn't properly trigger Sway's root window mouse bindings
- **Workaround**: Use keyboard shortcut `Mod4+d` or modifier+click combinations
- **Technical details**: This is a fundamental limitation of VNC/Wayland interaction, not a configuration issue

## Security Notes

- Container runs in **privileged mode** (required for Sway)
- VNC authentication is **disabled by default** (development only)
- For production, enable VNC auth and use SSH tunneling
- The `jovian` user has passwordless sudo access

## Troubleshooting

### VNC not accessible
```bash
# Check if port 5900 is listening
netstat -tuln | grep 5900

# Check service logs
just logs | grep -E "(Sway|wayvnc|Error)"

# Verify services are running
docker exec mcp-devops-dev ps aux | grep -E "(sway|wayvnc)"
```

### Permission issues
```bash
# Check workspace ownership
just check-workspace

# Fix permissions if needed
just fix-permissions
```

### Dev Container build issues
```bash
# If you encounter UID/GID errors during build:
# 1. Ensure you're using the latest devcontainer.json
# 2. The container uses default UID/GID 1000 for the jovian user
# 3. updateRemoteUserUID handles the UID sync automatically

# Test the Dev Container configuration
./scripts/test-devcontainer.sh

# Build manually to debug
docker build -t mcp-devops-devcontainer:debug .
```

### Launcher not working with right-click
```bash
# This is a known limitation - use keyboard shortcut instead
# Press Mod4+d (Super/Windows + D)

# Test launcher manually
docker exec mcp-devops-dev /usr/local/bin/launcher-strict.sh

# Check if wofi is installed
docker exec mcp-devops-dev which wofi

# Monitor binding events (for debugging)
docker exec mcp-devops-dev bash -c 'export SWAYSOCK=/tmp/runtime-jovian/$(ls /tmp/runtime-jovian | grep sway-ipc* | head -1); swaymsg -t subscribe -m "[\"binding\"]"'
```

### Container won't start
```bash
# Check for port conflicts
lsof -i :5900

# View detailed logs
docker logs mcp-devops-dev

# Check s6 service status
docker exec mcp-devops-dev ps aux | grep s6

# Rebuild from scratch
just clean && just up
```

## Implementation Details

### Why Privileged Mode?
Sway requires certain Linux capabilities to function, even in headless mode. Running with `--privileged` provides these capabilities. In production, consider using specific capabilities instead.

### S6 Overlay Benefits
- Proper service supervision and dependency management
- Clean startup/shutdown sequences
- Automatic service restart on failure
- Structured logging

### Wayland/Sway Headless
- Uses `WLR_BACKENDS=headless` for virtual display
- No physical GPU required
- Renders to memory buffer accessed by wayvnc
- Configured with seat0 for input device management
- Virtual pointer device created by wayvnc for mouse input

### Service Configuration
- **Sway**: Runs with `--unsupported-gpu -V` flags and WLR_SEAT=seat0
- **wayvnc**: Configured with `--seat=seat0 --render-cursor` for proper input handling
- **workspace-fix**: Oneshot service that ensures proper permissions at startup

## Recent Updates

### Configuration Improvements (Latest)
- **Input Handling**: Added seat0 configuration and virtual pointer device setup
- **Service Configuration**: Enhanced wayvnc with `--seat` and `--render-cursor` flags
- **Launcher Filtering**: Strict filtering to show only Terminal and Chrome
- **Auto-start**: Changed to launch only Terminal on startup (Chrome via launcher)
- **Mouse Bindings**: Multiple binding attempts added (though limited by VNC)
- **Documentation**: Added known limitations and workarounds

### Known Issues Being Investigated
- Direct right-click for launcher doesn't work through VNC (fundamental VNC/Wayland limitation)
- Workaround: Use `Mod4+d` keyboard shortcut for reliable launcher access

## License

MIT