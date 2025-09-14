# MCP DevOps Development Container

[![GitHub Release](https://img.shields.io/github/v/release/atrawog/mcp-devops)](https://github.com/atrawog/mcp-devops/releases)
[![Docker Image](https://img.shields.io/badge/ghcr.io-mcp--devops-blue)](https://github.com/atrawog/mcp-devops/pkgs/container/mcp-devops)
[![License](https://img.shields.io/badge/license-MIT-green)](LICENSE)

Arch Linux Wayland desktop development container with KRDC-compatible VNC access, designed for cloud-native development workflows.

![Desktop Preview](https://via.placeholder.com/800x400.png?text=MCP+DevOps+Desktop)

## 🚀 Quick Start

```bash
# Clone the repository
git clone https://github.com/atrawog/mcp-devops.git
cd mcp-devops

# Start the container
just up

# Connect via VNC client to localhost:5900
# Default password: mcp-devops
```

## 🐳 Docker Image

Pull the pre-built image from GitHub Container Registry:

```bash
# Latest version
docker pull ghcr.io/atrawog/mcp-devops:latest

# Specific version
docker pull ghcr.io/atrawog/mcp-devops:v1.0.0
```

### Run with Docker

```bash
# Run with default settings
docker run -d \
  --name mcp-devops \
  --privileged \
  -p 5900:5900 \
  -v $(pwd):/workspace \
  -v /var/run/docker.sock:/var/run/docker.sock \
  ghcr.io/atrawog/mcp-devops:latest

# Connect via VNC to localhost:5900
```

### Run with Docker Compose

```yaml
version: '3.8'
services:
  mcp-devops:
    image: ghcr.io/atrawog/mcp-devops:latest
    container_name: mcp-devops
    privileged: true
    ports:
      - "5900:5900"
    volumes:
      - .:/workspace
      - /var/run/docker.sock:/var/run/docker.sock
    environment:
      - VNC_PASSWORD=your-secure-password
```

## ✨ Features

### Core Components
- **Base OS**: Arch Linux (latest) - Rolling release for cutting-edge packages
- **Desktop**: Sway (Wayland compositor) running in headless mode
- **VNC Server**: wayvnc with KRDC compatibility
- **Terminal**: foot terminal emulator
- **Browser**: Google Chrome (installed from AUR)
- **Launcher**: wofi application launcher

### Development Tools
- **just** (v1.42.4) - Command runner for project automation
- **pixi** (v0.54.2) - Cross-platform package management (conda ecosystem)
- **opentofu** - Open-source infrastructure as code (Terraform fork)
- **Docker** - With automatic GID synchronization for socket access
- **Git** - Version control with full configuration support

### VS Code Integration
Full support for VS Code Dev Containers with:
- Automatic UID/GID mapping
- Pre-configured extensions
- Workspace persistence
- Docker-in-Docker support

## 📋 Requirements

- Docker Engine 20.10+
- VNC client (KRDC, TigerVNC, RealVNC, or any RFB-compatible client)
- 4GB RAM minimum (8GB recommended)
- 10GB disk space for the image

## 🎮 Usage

### Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| `Mod4+d` | Open application launcher |
| `Mod4+Return` | Open terminal |
| `Mod4+c` | Open Chrome browser |
| `Mod4+Shift+q` | Close current window |
| `Mod4+Shift+r` | Reload Sway configuration |
| `Mod4+Shift+e` | Exit Sway session |

### Just Commands

```bash
just --list                # Show all available commands
just up                    # Build and start container
just down                  # Stop and remove container
just rebuild               # Clean rebuild
just shell                 # Shell as root
just user-shell           # Shell as jovian user
just logs                 # View container logs
just test-dev             # Test development environment
just clean                # Remove container and image
```

### Development Workflow

1. **Start the container**:
   ```bash
   just up
   ```

2. **Connect via VNC**:
   - Open your VNC client
   - Connect to `localhost:5900`
   - Enter password if configured (default: `mcp-devops`)

3. **Open terminal**: Press `Mod4+Return` or use the launcher

4. **Access your workspace**: Files are mounted at `/workspace`

5. **Use development tools**:
   ```bash
   # Package management with pixi
   pixi init my-project
   pixi add python numpy pandas

   # Infrastructure as code with OpenTofu
   tofu init
   tofu plan
   tofu apply

   # Task automation with just
   just test
   just build
   ```

## 🔧 Configuration

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `VNC_PASSWORD` | `mcp-devops` | VNC authentication password |
| `USER_UID` | Current UID | Container user UID |
| `USER_GID` | Current GID | Container user GID |

### Custom VNC Password

```bash
# Set via environment variable
export VNC_PASSWORD="your-secure-password"
just up

# Or use the just command
just set-vnc-password "your-secure-password"
```

### Docker Socket Access

The container automatically synchronizes Docker group GID with the host:

```bash
# Verify Docker access
docker exec -u jovian mcp-devops-dev docker ps

# If permission denied, refresh groups
docker exec -u jovian mcp-devops-dev newgrp docker
```

## 🏗️ Architecture

```
mcp-devops/
├── config/
│   ├── s6/                 # Service management
│   ├── sway/               # Window manager config
│   ├── wayvnc/             # VNC server config
│   ├── wofi/               # App launcher
│   └── waybar/             # Status bar
├── scripts/
│   ├── docker-entrypoint.sh
│   └── launcher-strict.sh
├── .devcontainer/          # VS Code config
├── Dockerfile
├── Justfile               # Task automation
└── README.md
```

### Service Stack
- **Init**: s6-overlay for process supervision
- **Display**: Wayland (headless backend)
- **Compositor**: Sway window manager
- **VNC**: wayvnc server on port 5900
- **Apps**: Terminal and Chrome browser

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🐛 Troubleshooting

### VNC Connection Issues
```bash
# Check if VNC is running
just status

# View VNC logs
just service-logs wayvnc

# Test VNC connectivity
just test-vnc
```

### Permission Problems
```bash
# Check workspace permissions
just check-workspace

# Fix permissions if needed
just fix-permissions
```

### Container Won't Start
```bash
# Check for port conflicts
lsof -i :5900

# View detailed logs
just logs

# Clean rebuild
just clean && just up
```

## 📚 Documentation

- [CLAUDE.md](CLAUDE.md) - Comprehensive technical documentation
- [LAUNCHER.md](LAUNCHER.md) - Application launcher details
- [MOUSE-BINDING-STATUS.md](MOUSE-BINDING-STATUS.md) - Input device configuration

## 🔗 Links

- [GitHub Repository](https://github.com/atrawog/mcp-devops)
- [Container Registry](https://github.com/atrawog/mcp-devops/pkgs/container/mcp-devops)
- [Issue Tracker](https://github.com/atrawog/mcp-devops/issues)
- [Releases](https://github.com/atrawog/mcp-devops/releases)

## 👥 Author

**atrawog** - [GitHub Profile](https://github.com/atrawog)

## 🙏 Acknowledgments

- Arch Linux community for the base image
- Sway developers for the Wayland compositor
- wayvnc project for VNC server implementation
- s6-overlay for process supervision
- All contributors and users of this project

---

Made with ❤️ for the cloud-native development community