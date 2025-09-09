# MCP DevOps Development Container

Arch Linux Wayland desktop development container with KRDC-compatible VNC access.

## Stack
- **Base**: Arch Linux (latest)
- **Init**: s6-overlay
- **Compositor**: Sway (Wayland)
- **VNC**: wayvnc (KRDC compatible)
- **Browser**: Google Chrome
- **Task Runner**: just
- **Default User**: jovian (uid=1000)

## Quick Start

```bash
# Build and run dev container
just up
```

## Justfile

```makefile
# Default recipe
default:
    @just --list

# Project variables
project := "mcp-devops"
image := "mcp-devops:latest"
container := "mcp-devops-dev"
vnc_port := "5900"
vnc_password := env_var_or_default("VNC_PASSWORD", "mcp-devops")
user_id := `id -u`
group_id := `id -g`

# Build the development container
build:
    docker build \
        --build-arg USER_UID={{user_id}} \
        --build-arg USER_GID={{group_id}} \
        -t {{image}} .

# Run the container
up: build
    docker run -d \
        --name {{container}} \
        --hostname {{project}} \
        -p {{vnc_port}}:5900 \
        -v $(pwd):/workspace:cached \
        -v /var/run/docker.sock:/var/run/docker.sock \
        -e VNC_PASSWORD={{vnc_password}} \
        -e USER_UID={{user_id}} \
        -e USER_GID={{group_id}} \
        --user {{user_id}}:{{group_id}} \
        --cap-add SYS_PTRACE \
        --security-opt seccomp=unconfined \
        --shm-size=2g \
        {{image}}
    @echo "VNC server starting on port {{vnc_port}}"
    @echo "Password: {{vnc_password}}"
    @sleep 2
    @just test-vnc

# Stop and remove container
down:
    docker stop {{container}} || true
    docker rm {{container}} || true

# Rebuild and restart
rebuild: down build up

# Shell into container as root
shell:
    docker exec -it -u root {{container}} bash

# Shell as jovian user
user-shell:
    docker exec -it {{container}} bash

# View logs
logs:
    docker logs -f {{container}}

# View specific service logs
service-logs service:
    docker exec {{container}} tail -f /var/log/s6-uncaught-logs/current | grep {{service}}

# Check service status
status:
    @echo "=== S6 Service Status ==="
    docker exec {{container}} s6-svstat /run/service/*
    @echo "\n=== Wayland Status ==="
    docker exec {{container}} bash -c 'export XDG_RUNTIME_DIR=/tmp/runtime-jovian && wayland-info' || true
    @echo "\n=== Process Status ==="
    docker exec {{container}} pgrep -a sway || echo "Sway not running"
    docker exec {{container}} pgrep -a wayvnc || echo "WayVNC not running"

# Check workspace permissions
check-workspace:
    @echo "=== Workspace Permissions ==="
    docker exec {{container}} ls -la /workspace
    @echo "\n=== User Info ==="
    docker exec {{container}} id
    @echo "\n=== Workspace Owner ==="
    docker exec {{container}} stat -c "%u:%g (%U:%G)" /workspace

# Fix workspace permissions if needed
fix-permissions:
    docker exec -u root {{container}} chown -R jovian:jovian /workspace
    docker exec -u root {{container}} chmod -R u+rw /workspace

# Clean everything
clean: down
    docker rmi {{image}} || true
    docker volume prune -f

# Reset VNC password
set-vnc-password password:
    docker exec {{container}} bash -c 'echo "{{password}}" | wayvncctl set-password'

# Show container info
info:
    @echo "Project: {{project}}"
    @echo "Image: {{image}}"
    @echo "Container: {{container}}"
    @echo "VNC Port: {{vnc_port}}"
    @echo "VNC Password: {{vnc_password}}"
    @echo "Host UID/GID: {{user_id}}/{{group_id}}"
    @docker inspect {{container}} --format='Status: {{.State.Status}}' 2>/dev/null || echo "Status: Not running"

# Dev environment test
test-dev:
    @echo "=== Testing Development Environment ==="
    docker exec {{container}} bash -c 'cd /workspace && echo "test" > test.txt && rm test.txt' && \
        echo "✓ Workspace is writable" || \
        echo "✗ Workspace permission issue"
    docker exec {{container}} which just && \
        echo "✓ Just is installed" || \
        echo "✗ Just not found"
    docker exec {{container}} which google-chrome-stable && \
        echo "✓ Chrome is installed" || \
        echo "✗ Chrome not found"
```

## devcontainer.json

```json
{
  "name": "MCP DevOps",
  "build": {
    "dockerfile": "Dockerfile",
    "context": ".",
    "args": {
      "USER_UID": "${localEnv:USER_UID:-1000}",
      "USER_GID": "${localEnv:USER_GID:-1000}"
    }
  },
  "runArgs": [
    "--hostname=mcp-devops",
    "--cap-add=SYS_PTRACE",
    "--security-opt", "seccomp=unconfined",
    "--shm-size=2g",
    "--user", "${localEnv:USER_UID:-1000}:${localEnv:USER_GID:-1000}"
  ],
  "forwardPorts": [5900],
  "portsAttributes": {
    "5900": {
      "label": "VNC",
      "onAutoForward": "notify",
      "protocol": "tcp"
    }
  },
  "customizations": {
    "vscode": {
      "extensions": [
        "ms-azuretools.vscode-docker",
        "kokakiwi.vscode-just",
        "ms-vscode.makefile-tools",
        "ms-kubernetes-tools.vscode-kubernetes-tools"
      ],
      "settings": {
        "terminal.integrated.defaultProfile.linux": "bash",
        "remote.autoForwardPorts": true,
        "remote.containers.defaultExtensions": [
          "kokakiwi.vscode-just"
        ],
        "files.watcherExclude": {
          "**/target/**": true
        }
      }
    }
  },
  "features": {
    "ghcr.io/devcontainers/features/docker-in-docker:2": {
      "version": "latest",
      "moby": true,
      "dockerDashComposeVersion": "v2"
    },
    "ghcr.io/devcontainers/features/git:1": {
      "version": "latest",
      "ppa": false
    }
  },
  "postCreateCommand": "",
  "postStartCommand": "/init",
  "remoteUser": "jovian",
  "workspaceFolder": "/workspace",
  "workspaceMount": "source=${localWorkspaceFolder},target=/workspace,type=bind,consistency=cached",
  "mounts": [
    "source=/var/run/docker.sock,target=/var/run/docker-host.sock,type=bind"
  ],
  "initializeCommand": "echo 'Starting MCP DevOps container with UID='$(id -u)",
  "updateContentCommand": "sudo pacman -Syu --noconfirm",
  "containerEnv": {
    "PROJECT_NAME": "mcp-devops",
    "DISPLAY": ":0",
    "WLR_BACKENDS": "headless",
    "WLR_LIBINPUT_NO_DEVICES": "1",
    "XDG_RUNTIME_DIR": "/tmp/runtime-jovian",
    "WAYLAND_DISPLAY": "wayland-1"
  },
  "containerUser": "jovian",
  "updateRemoteUserUID": true
}
```

## Dockerfile

```dockerfile
FROM archlinux:latest

# Dev Container metadata
LABEL devcontainer.metadata='{ \
  "id": "mcp-devops", \
  "version": "1.0.0", \
  "name": "MCP DevOps Development Container", \
  "description": "Wayland desktop with KRDC-compatible VNC for DevOps workflows" \
}'

# Project metadata
LABEL org.opencontainers.image.title="MCP DevOps" \
      org.opencontainers.image.description="Development container for MCP DevOps" \
      org.opencontainers.image.vendor="MCP DevOps Team"

# Arguments for UID/GID mapping
ARG USER_UID=1000
ARG USER_GID=1000

# Install s6-overlay
ARG S6_OVERLAY_VERSION=3.1.6.2
ADD https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-noarch.tar.xz /tmp
ADD https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-x86_64.tar.xz /tmp
RUN tar -C / -Jxpf /tmp/s6-overlay-noarch.tar.xz && \
    tar -C / -Jxpf /tmp/s6-overlay-x86_64.tar.xz && \
    rm /tmp/*.tar.xz

# System packages
RUN pacman -Syu --noconfirm && \
    pacman -S --noconfirm \
    base-devel \
    git \
    sudo \
    sway \
    wayvnc \
    xorg-xwayland \
    wlroots \
    mesa \
    ttf-liberation \
    foot \
    just \
    neovim \
    openssh \
    rsync \
    wayland-utils \
    net-tools \
    iproute2 \
    shadow

# Create jovian user with specific UID/GID for proper workspace mapping
RUN groupadd --gid ${USER_GID} jovian && \
    useradd --uid ${USER_UID} --gid ${USER_GID} -m -s /bin/bash jovian && \
    usermod -aG wheel jovian && \
    echo "jovian ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/jovian && \
    chmod 0440 /etc/sudoers.d/jovian

# Create workspace with proper ownership
RUN mkdir -p /workspace && \
    chown ${USER_UID}:${USER_GID} /workspace && \
    chmod 755 /workspace

# Install yay for AUR packages
USER jovian
WORKDIR /tmp
RUN git clone https://aur.archlinux.org/yay.git && \
    cd yay && \
    makepkg -si --noconfirm && \
    cd .. && rm -rf yay

# Install Chrome from AUR
RUN yay -S --noconfirm google-chrome

USER root

# Configure VNC and runtime directories
RUN mkdir -p /home/jovian/.config/wayvnc && \
    mkdir -p /tmp/runtime-jovian && \
    chown -R ${USER_UID}:${USER_GID} /home/jovian/.config && \
    chown ${USER_UID}:${USER_GID} /tmp/runtime-jovian && \
    chmod 700 /tmp/runtime-jovian

# S6 service configuration with proper permissions
RUN mkdir -p /etc/s6-overlay/s6-rc.d/user/contents.d \
             /etc/s6-overlay/s6-rc.d/sway \
             /etc/s6-overlay/s6-rc.d/wayvnc \
             /etc/s6-overlay/s6-rc.d/workspace-fix

# Workspace permissions fix service (oneshot)
RUN echo "oneshot" > /etc/s6-overlay/s6-rc.d/workspace-fix/type && \
    echo "#!/command/with-contenv bash\n\
# Fix workspace ownership at startup\n\
if [ -n \"\${USER_UID}\" ] && [ -n \"\${USER_GID}\" ]; then\n\
    echo \"Setting workspace ownership to \${USER_UID}:\${USER_GID}\"\n\
    chown -R \${USER_UID}:\${USER_GID} /workspace 2>/dev/null || true\n\
    chown -R \${USER_UID}:\${USER_GID} /home/jovian 2>/dev/null || true\n\
    chown \${USER_UID}:\${USER_GID} /tmp/runtime-jovian 2>/dev/null || true\n\
fi\n\
# Ensure runtime directory exists\n\
mkdir -p /tmp/runtime-jovian\n\
chown jovian:jovian /tmp/runtime-jovian\n\
chmod 700 /tmp/runtime-jovian" \
    > /etc/s6-overlay/s6-rc.d/workspace-fix/up && \
    chmod +x /etc/s6-overlay/s6-rc.d/workspace-fix/up && \
    touch /etc/s6-overlay/s6-rc.d/user/contents.d/workspace-fix

# Sway service
RUN echo "longrun" > /etc/s6-overlay/s6-rc.d/sway/type && \
    echo "#!/command/with-contenv bash\n\
export XDG_RUNTIME_DIR=/tmp/runtime-jovian\n\
export HOME=/home/jovian\n\
export WLR_BACKENDS=headless\n\
export WLR_LIBINPUT_NO_DEVICES=1\n\
export WAYLAND_DISPLAY=wayland-1\n\
# Ensure runtime dir exists and has correct permissions\n\
mkdir -p \$XDG_RUNTIME_DIR\n\
chown jovian:jovian \$XDG_RUNTIME_DIR\n\
chmod 700 \$XDG_RUNTIME_DIR\n\
echo \"Starting Sway as jovian user\"\n\
exec s6-setuidgid jovian sway --unsupported-gpu -V" \
    > /etc/s6-overlay/s6-rc.d/sway/run && \
    chmod +x /etc/s6-overlay/s6-rc.d/sway/run && \
    mkdir -p /etc/s6-overlay/s6-rc.d/sway/dependencies.d && \
    touch /etc/s6-overlay/s6-rc.d/sway/dependencies.d/workspace-fix && \
    touch /etc/s6-overlay/s6-rc.d/user/contents.d/sway

# WayVNC service
RUN echo "longrun" > /etc/s6-overlay/s6-rc.d/wayvnc/type && \
    echo "#!/command/with-contenv bash\n\
export XDG_RUNTIME_DIR=/tmp/runtime-jovian\n\
export HOME=/home/jovian\n\
export WAYLAND_DISPLAY=wayland-1\n\
# Wait for Sway to fully initialize\n\
sleep 5\n\
# Check if Wayland socket exists\n\
count=0\n\
while [ ! -S \$XDG_RUNTIME_DIR/\$WAYLAND_DISPLAY ]; do\n\
    echo \"Waiting for Wayland socket...\"\n\
    sleep 1\n\
    count=\$((count + 1))\n\
    if [ \$count -gt 30 ]; then\n\
        echo \"Timeout waiting for Wayland socket\"\n\
        exit 1\n\
    fi\n\
done\n\
echo \"Starting wayvnc on HEADLESS-1\"\n\
exec s6-setuidgid jovian wayvnc --config=/home/jovian/.config/wayvnc/config 0.0.0.0 5900" \
    > /etc/s6-overlay/s6-rc.d/wayvnc/run && \
    chmod +x /etc/s6-overlay/s6-rc.d/wayvnc/run && \
    mkdir -p /etc/s6-overlay/s6-rc.d/wayvnc/dependencies.d && \
    touch /etc/s6-overlay/s6-rc.d/wayvnc/dependencies.d/sway && \
    touch /etc/s6-overlay/s6-rc.d/user/contents.d/wayvnc

# Sway configuration
RUN mkdir -p /home/jovian/.config/sway && \
    echo '# MCP DevOps Sway Configuration\n\
# Output configuration\n\
output HEADLESS-1 {\n\
    mode 1920x1080@60Hz\n\
    bg #1a1b26 solid_color\n\
}\n\
\n\
# Default applications\n\
exec foot --title=Terminal\n\
exec google-chrome-stable --no-sandbox --disable-dev-shm-usage --disable-gpu-sandbox\n\
\n\
# Window rules\n\
default_border pixel 2\n\
gaps inner 10\n\
smart_gaps on\n\
\n\
# Colors\n\
client.focused          #7aa2f7 #7aa2f7 #1a1b26 #7dcfff\n\
client.focused_inactive #414868 #414868 #a9b1d6 #414868\n\
client.unfocused        #24283b #24283b #a9b1d6 #24283b\n\
\n\
# Keybindings\n\
set $mod Mod4\n\
bindsym $mod+Return exec foot\n\
bindsym $mod+d exec google-chrome-stable --no-sandbox\n\
bindsym $mod+Shift+q kill\n\
bindsym $mod+Shift+e exec swaynag -t warning -m "Exit Sway?" -B "Yes" "swaymsg exit"\n\
bindsym $mod+Shift+r reload\n\
\n\
# Focus\n\
bindsym $mod+h focus left\n\
bindsym $mod+j focus down\n\
bindsym $mod+k focus up\n\
bindsym $mod+l focus right\n\
\n\
# Move windows\n\
bindsym $mod+Shift+h move left\n\
bindsym $mod+Shift+j move down\n\
bindsym $mod+Shift+k move up\n\
bindsym $mod+Shift+l move right\n\
\n\
# Workspaces\n\
bindsym $mod+1 workspace 1\n\
bindsym $mod+2 workspace 2\n\
bindsym $mod+3 workspace 3\n\
bindsym $mod+4 workspace 4\n\
\n\
# Container layout\n\
bindsym $mod+s layout stacking\n\
bindsym $mod+w layout tabbed\n\
bindsym $mod+e layout toggle split\n\
bindsym $mod+f fullscreen toggle' \
    > /home/jovian/.config/sway/config && \
    chown -R ${USER_UID}:${USER_GID} /home/jovian/.config

# Create wayvnc config for KRDC compatibility
RUN echo "address=0.0.0.0\n\
port=5900\n\
enable_auth=false" \
    > /home/jovian/.config/wayvnc/config && \
    chown -R ${USER_UID}:${USER_GID} /home/jovian/.config/wayvnc

# Create a startup script for workspace permissions
RUN echo '#!/bin/bash\n\
if [ "$EUID" -eq 0 ]; then\n\
    if [ -n "${USER_UID}" ] && [ -n "${USER_GID}" ]; then\n\
        usermod -u ${USER_UID} jovian 2>/dev/null || true\n\
        groupmod -g ${USER_GID} jovian 2>/dev/null || true\n\
        chown -R ${USER_UID}:${USER_GID} /home/jovian 2>/dev/null || true\n\
        chown -R ${USER_UID}:${USER_GID} /workspace 2>/dev/null || true\n\
    fi\n\
fi\n\
exec "$@"' > /usr/local/bin/docker-entrypoint.sh && \
    chmod +x /usr/local/bin/docker-entrypoint.sh

# Environment
ENV S6_CMD_WAIT_FOR_SERVICES_MAXTIME=30000 \
    S6_VERBOSITY=2 \
    S6_KEEP_ENV=1 \
    S6_FIX_ATTRS_HIDDEN=1 \
    DISPLAY_WIDTH=1920 \
    DISPLAY_HEIGHT=1080 \
    PROJECT_NAME=mcp-devops \
    USER=jovian

# Set working directory
WORKDIR /workspace

# VNC port
EXPOSE 5900

# Volume for persistent data
VOLUME ["/workspace", "/home/jovian"]

# Entry point with permission fix
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh", "/init"]
```

## KRDC Configuration

### Connection Settings
1. Open KRDC
2. Create new connection:
   - **Protocol**: VNC
   - **Server**: `localhost:5900`
   - **Name**: MCP DevOps
3. Connection Options:
   - **Quality**: High (LAN)
   - **Show local cursor**: Yes
   - **Scale to fit window**: Optional

### Troubleshooting KRDC

| Issue | Solution |
|-------|----------|
| Connection refused | Verify wayvnc is running: `just test-vnc` |
| Black screen | Wait 5-10 seconds for Sway initialization |
| Authentication failed | Check VNC_PASSWORD env var: `just info` |
| Poor performance | Set Quality to "Low (Modem)" in KRDC |
| No response | Check if container is running: `just status` |

## UID/GID Mapping

The container automatically maps the host user's UID/GID to the `jovian` user inside the container:

```bash
# Check current mapping
just check-workspace

# Fix permissions if needed
just fix-permissions

# Test development environment
just test-dev
```

### How it works:
1. Build time: `USER_UID` and `USER_GID` are baked into the image
2. Runtime: The entrypoint adjusts ownership if different UIDs are provided
3. VS Code: Uses `updateRemoteUserUID` to ensure consistency

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `VNC_PASSWORD` | `mcp-devops` | VNC authentication (if auth enabled) |
| `DISPLAY_WIDTH` | `1920` | Screen width |
| `DISPLAY_HEIGHT` | `1080` | Screen height |
| `WLR_BACKENDS` | `headless` | Wayland backend |
| `WLR_LIBINPUT_NO_DEVICES` | `1` | Disable input devices |
| `PROJECT_NAME` | `mcp-devops` | Project identifier |
| `USER_UID` | `1000` | User ID for jovian |
| `USER_GID` | `1000` | Group ID for jovian |

## Usage

### Quick Start with KRDC
```bash
# Start container (auto-detects your UID/GID)
just up

# Test workspace permissions
just check-workspace
```

### Development Workflow
```bash
# View service status
just status

# Shell as jovian user (default)
just user-shell

# Shell as root (for admin tasks)
just shell

```

## Security Notes

- The `jovian` user has passwordless sudo for development
- VNC runs without authentication by default for development
- For production, enable auth in wayvnc config:
  ```bash
  docker exec mcp-devops-dev bash -c 'echo "enable_auth=true" >> /home/jovian/.config/wayvnc/config'
  ```
- Use SSH tunnel for secure remote access:
  ```bash
  ssh -L 5900:localhost:5900 remote-host
  ```

## Testing Checklist

✓ Container builds successfully  
✓ UID/GID mapping works correctly  
✓ Workspace is writable by jovian user  
✓ S6 services start in correct order  
✓ Sway creates HEADLESS-1 output  
✓ WayVNC binds to port 5900  
✓ KRDC connects without issues  
✓ Chrome launches in Sway  
✓ Keyboard/mouse input works  
✓ VS Code Dev Container opens  
✓ Files created in VS Code have correct ownership  

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Permission denied in /workspace | Run: `just fix-permissions` |
| Services not starting | Check: `just status` |
| Wrong file ownership | Verify UID/GID: `just check-workspace` |
| Black VNC screen | Verify Sway: `just logs \| grep sway` |
| Chrome crashes | Ensure `--shm-size=2g` is set |
| Can't write files in VS Code | Check: `just test-dev` |

## License

MIT