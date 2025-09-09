# MCP DevOps Development Container

Arch Linux Wayland desktop development container with KRDC-compatible VNC access.

## Quick Start

```bash
# Build and run container with VNC on port 5900
just up

# Connect via VNC client to localhost:5900
# Password: mcp-devops (or set VNC_PASSWORD env var)
```

## Architecture

### Stack
- **Base**: Arch Linux (latest)
- **Init**: s6-overlay for service management
- **Compositor**: Sway (Wayland) in headless mode
- **VNC**: wayvnc for KRDC-compatible remote access
- **Browser**: Google Chrome (installed from AUR)
- **Launcher**: wofi (app launcher) and waybar (taskbar)
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
│   └── applications/       # Desktop entries for launcher
├── scripts/
│   └── docker-entrypoint.sh # Container entrypoint
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
- Launches foot terminal and Chrome on startup
- Modern Tokyo Night color scheme
- Standard keybindings (Mod4+Enter for terminal, etc.)

### WayVNC Configuration
- Listens on all interfaces (0.0.0.0:5900)
- Authentication disabled by default for development
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

## VNC Access

### Connecting with KRDC
1. Open KRDC
2. Create new VNC connection to `localhost:5900`
3. No authentication required (default)
4. You'll see Sway desktop with terminal and Chrome

### Desktop Features
- **Launcher**: Right-click anywhere on desktop to open app launcher (wofi)
- **Taskbar**: Bottom bar with app launchers and system info (waybar)
- **Quick Launch**: Click icons in taskbar for Terminal and Chrome
- **Keyboard Shortcuts**:
  - `Mod4+d`: Open app launcher
  - `Mod4+Return`: Open terminal
  - `Mod4+c`: Open Chrome
  - `Mod4+Shift+q`: Close window

### Connecting with other VNC clients
Any VNC client supporting the RFB protocol should work:
- TigerVNC: `vncviewer localhost:5900`
- RealVNC: Connect to `localhost:5900`
- macOS Screen Sharing: `vnc://localhost:5900`

## Development Features

### UID/GID Mapping
The container automatically maps your host user's UID/GID to the `jovian` user inside the container, ensuring proper file permissions for the workspace.

### Docker-in-Docker
The container has access to the host's Docker socket, allowing Docker commands to work inside the container.

### VS Code Dev Container
Includes `.devcontainer/devcontainer.json` configuration for seamless VS Code integration with proper extensions and settings.

### Workspace Persistence
The current directory is mounted at `/workspace` with proper ownership, allowing persistent development work.

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

### Container won't start
```bash
# Check for port conflicts
lsof -i :5900

# View detailed logs
docker logs mcp-devops-dev

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

## License

MIT