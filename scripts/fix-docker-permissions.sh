#!/bin/bash
# Script to fix Docker socket permissions if they get corrupted

echo "=== Docker Permissions Fix ==="
echo ""

# Check current Docker socket permissions
echo "Current Docker socket permissions:"
ls -la /var/run/docker.sock
echo ""

# Get the actual group ownership
CURRENT_GROUP=$(stat -c %G /var/run/docker.sock)
if [ "$CURRENT_GROUP" != "docker" ]; then
    echo "✗ Docker socket has wrong group: $CURRENT_GROUP (should be 'docker')"
    echo "Fixing..."
    sudo chown root:docker /var/run/docker.sock
    echo "✓ Fixed Docker socket ownership to root:docker"
else
    echo "✓ Docker socket group is correct: docker"
fi

# Verify permissions
echo ""
echo "Verifying permissions:"
ls -la /var/run/docker.sock

# Check if current user is in docker group
if groups | grep -q docker; then
    echo "✓ Current user is in docker group"
else
    echo "✗ Current user is NOT in docker group"
    echo "To add yourself to docker group, run:"
    echo "  sudo usermod -aG docker $USER"
    echo "Then log out and log back in."
fi

# Test Docker access
echo ""
echo "Testing Docker access:"
if docker ps >/dev/null 2>&1; then
    echo "✓ Docker is accessible"
    docker version --format 'Docker version: {{.Server.Version}}'
else
    echo "✗ Docker is not accessible"
    echo "Try running: newgrp docker"
fi

echo ""
echo "=== Troubleshooting Tips ==="
echo "If Docker still doesn't work:"
echo "1. Restart Docker service: sudo systemctl restart docker.socket docker.service"
echo "2. Check service status: systemctl status docker.socket docker.service"
echo "3. Ensure you're in docker group: groups | grep docker"
echo "4. Try new group session: newgrp docker"