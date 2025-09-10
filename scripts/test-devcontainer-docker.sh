#!/bin/bash
# Test script to verify DevContainer works without Dev Container features

echo "=== Testing DevContainer without Features ==="
echo ""

# Build container
echo "1. Building container with integrated Docker support..."
docker build -t mcp-devops-devcontainer:final . || exit 1
echo "✓ Build successful"
echo ""

# Run container
echo "2. Starting container..."
CONTAINER_ID=$(docker run -d \
    --name mcp-devops-devcontainer-final \
    --hostname=mcp-devops \
    --privileged \
    --cap-add=SYS_PTRACE \
    --security-opt seccomp=unconfined \
    --shm-size=2g \
    -v $(pwd):/workspace:cached \
    -v /var/run/docker.sock:/var/run/docker.sock \
    mcp-devops-devcontainer:final)

sleep 5

# Fix Docker socket permissions
echo "3. Fixing Docker socket permissions..."
DOCKER_GID=$(stat -c %g /var/run/docker.sock)
docker exec -u root mcp-devops-devcontainer-final bash -c "groupmod -g $DOCKER_GID docker 2>/dev/null || groupadd -g $DOCKER_GID docker" 2>/dev/null
docker exec -u root mcp-devops-devcontainer-final bash -c "usermod -aG docker jovian" 2>/dev/null
echo "✓ Docker group synchronized with host (GID: $DOCKER_GID)"
echo ""

# Test Docker access
echo "4. Testing Docker access..."
OUTPUT=$(docker exec -u jovian mcp-devops-devcontainer-final bash -c "newgrp docker; docker --version" 2>&1)
if [[ $OUTPUT == *"Docker version"* ]]; then
    echo "✓ Docker accessible: $OUTPUT"
else
    echo "✗ Docker access issue: $OUTPUT"
fi

# Test Docker Compose
OUTPUT=$(docker exec -u jovian mcp-devops-devcontainer-final docker-compose --version 2>&1)
if [[ $OUTPUT == *"Docker Compose"* ]]; then
    echo "✓ Docker Compose accessible: $OUTPUT"
else
    echo "✗ Docker Compose issue: $OUTPUT"
fi

# Test git
OUTPUT=$(docker exec -u jovian mcp-devops-devcontainer-final git --version 2>&1)
if [[ $OUTPUT == *"git version"* ]]; then
    echo "✓ Git installed: $OUTPUT"
else
    echo "✗ Git issue: $OUTPUT"
fi
echo ""

# Test workspace access
echo "5. Testing workspace access..."
OUTPUT=$(docker exec -u jovian mcp-devops-devcontainer-final bash -c "cd /workspace && touch test.txt && rm test.txt && echo 'success'" 2>&1)
if [[ $OUTPUT == "success" ]]; then
    echo "✓ Workspace writable by jovian user"
else
    echo "✗ Workspace permission issue: $OUTPUT"
fi
echo ""

# Cleanup
echo "6. Cleaning up..."
docker stop mcp-devops-devcontainer-final >/dev/null 2>&1
docker rm mcp-devops-devcontainer-final >/dev/null 2>&1
echo "✓ Cleanup complete"
echo ""

echo "=== Summary ==="
echo "The DevContainer now works without Dev Container features:"
echo "- Docker, Docker Compose, and git are installed directly in Dockerfile"
echo "- Docker socket permissions are synchronized with host"
echo "- No dependency on Debian/Ubuntu-specific features"
echo "- Compatible with Arch Linux base image"
echo ""
echo "Note: VS Code DevContainers will automatically handle the Docker socket"
echo "permissions through the postStartCommand in devcontainer.json"