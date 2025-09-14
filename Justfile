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

# Push image to GitHub Container Registry
push: build
    #!/usr/bin/env bash
    set -euo pipefail

    # Variables
    REGISTRY="ghcr.io"
    USERNAME="atrawog"
    IMAGE_NAME="mcp-devops"
    COMMIT_SHA=$(git rev-parse --short HEAD)
    VERSION=$(git describe --tags --abbrev=0 2>/dev/null || echo "v1.0.0")

    echo "=== Pushing Docker image to GitHub Container Registry ==="

    # Login to ghcr.io
    echo "Logging in to ${REGISTRY}..."
    if [ -n "${GITHUB_TOKEN:-}" ]; then
        echo "$GITHUB_TOKEN" | docker login ${REGISTRY} -u ${USERNAME} --password-stdin
    else
        echo "Using gh CLI for authentication..."
        gh auth token | docker login ${REGISTRY} -u ${USERNAME} --password-stdin
    fi

    # Tag images
    echo "Tagging images..."
    docker tag {{image}} ${REGISTRY}/${USERNAME}/${IMAGE_NAME}:latest
    docker tag {{image}} ${REGISTRY}/${USERNAME}/${IMAGE_NAME}:${VERSION}
    docker tag {{image}} ${REGISTRY}/${USERNAME}/${IMAGE_NAME}:${COMMIT_SHA}

    # Push images
    echo "Pushing images to ${REGISTRY}..."
    docker push ${REGISTRY}/${USERNAME}/${IMAGE_NAME}:latest
    docker push ${REGISTRY}/${USERNAME}/${IMAGE_NAME}:${VERSION}
    docker push ${REGISTRY}/${USERNAME}/${IMAGE_NAME}:${COMMIT_SHA}

    echo "✅ Successfully pushed images:"
    echo "  - ${REGISTRY}/${USERNAME}/${IMAGE_NAME}:latest"
    echo "  - ${REGISTRY}/${USERNAME}/${IMAGE_NAME}:${VERSION}"
    echo "  - ${REGISTRY}/${USERNAME}/${IMAGE_NAME}:${COMMIT_SHA}"

    echo ""
    echo "📦 View package at: https://github.com/${USERNAME}/${IMAGE_NAME}/pkgs/container/${IMAGE_NAME}"

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
        --privileged \
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
    @docker inspect {{container}} --format='Status: {{ "{{.State.Status}}" }}' 2>/dev/null || echo "Status: Not running"

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

# Test VNC connectivity
test-vnc:
    @echo "=== Testing VNC Connectivity ==="
    @nc -zv localhost {{vnc_port}} 2>&1 | grep -q succeeded && \
        echo "✓ VNC port {{vnc_port}} is accessible" || \
        echo "✗ VNC port {{vnc_port}} is not accessible"

# Fix Docker permissions if lost
fix-docker:
    @./scripts/fix-docker-permissions.sh

# Verify Docker permissions in devcontainer
verify-docker:
    @./scripts/verify-docker-permissions.sh

# Test development tools (just, pixi, terraform)
test-devtools:
    @./scripts/test-devtools.sh

# Comprehensive verification of all tools
verify-tools:
    @./scripts/verify-all-tools.sh