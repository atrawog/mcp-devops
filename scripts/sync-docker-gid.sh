#!/bin/bash
# Script to synchronize Docker GID with host when socket is mounted
# This ensures the jovian user can access the Docker socket

set -e

SOCKET_PATH="/var/run/docker.sock"
USER="jovian"

echo "=== Docker Socket Permission Sync ==="

# Check if Docker socket exists
if [ ! -e "$SOCKET_PATH" ]; then
    echo "Docker socket not found at $SOCKET_PATH"
    echo "Docker functionality will not be available"
    exit 0
fi

# Get the GID of the Docker socket
DOCKER_GID=$(stat -c '%g' "$SOCKET_PATH")
echo "Host Docker socket GID: $DOCKER_GID"

# Check if docker group exists
if getent group docker >/dev/null 2>&1; then
    CURRENT_DOCKER_GID=$(getent group docker | cut -d: -f3)
    echo "Current container docker group GID: $CURRENT_DOCKER_GID"
    
    if [ "$CURRENT_DOCKER_GID" != "$DOCKER_GID" ]; then
        echo "GID mismatch detected, updating..."
        
        # Check if the target GID is already taken by another group
        if getent group "$DOCKER_GID" >/dev/null 2>&1; then
            EXISTING_GROUP=$(getent group "$DOCKER_GID" | cut -d: -f1)
            echo "GID $DOCKER_GID is already used by group: $EXISTING_GROUP"
            
            # If it's not the docker group, we need to handle this
            if [ "$EXISTING_GROUP" != "docker" ]; then
                echo "Creating docker-host group with GID $DOCKER_GID"
                groupadd -g "$DOCKER_GID" docker-host 2>/dev/null || true
                usermod -aG docker-host "$USER"
                echo "Added $USER to docker-host group"
            fi
        else
            # GID is free, update docker group
            echo "Updating docker group GID to $DOCKER_GID"
            groupmod -g "$DOCKER_GID" docker
            echo "Docker group GID updated successfully"
        fi
    else
        echo "Docker group GID is already correct"
    fi
else
    # Docker group doesn't exist, create it with correct GID
    echo "Creating docker group with GID $DOCKER_GID"
    groupadd -g "$DOCKER_GID" docker
    echo "Docker group created"
fi

# Ensure jovian user is in the docker group
if id -nG "$USER" | grep -qw "docker"; then
    echo "$USER is already in docker group"
else
    echo "Adding $USER to docker group"
    usermod -aG docker "$USER"
    echo "$USER added to docker group"
fi

# Also check for docker-host group if it exists
if getent group docker-host >/dev/null 2>&1; then
    if ! id -nG "$USER" | grep -qw "docker-host"; then
        usermod -aG docker-host "$USER"
        echo "$USER added to docker-host group"
    fi
fi

# Verify access
echo ""
echo "Verifying Docker socket access for $USER:"
if sudo -u "$USER" test -r "$SOCKET_PATH" && sudo -u "$USER" test -w "$SOCKET_PATH"; then
    echo "✓ $USER can access Docker socket"
else
    echo "⚠ $USER may need to start a new shell session to access Docker"
    echo "  Run: newgrp docker"
fi

echo ""
echo "Final group membership for $USER:"
id "$USER"
echo ""
echo "Docker socket permissions:"
ls -la "$SOCKET_PATH"
echo ""
echo "=== Docker Permission Sync Complete ==="