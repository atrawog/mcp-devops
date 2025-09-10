#!/bin/bash
# Test script to verify Docker permissions work correctly for jovian user

echo "=== Testing Docker Permissions in DevContainer ==="
echo ""

# Build the container
echo "1. Building container with Docker permission sync..."
docker build -t mcp-devops-docker-test:latest . || exit 1
echo "✓ Build successful"
echo ""

# Start container
echo "2. Starting container with Docker socket mounted..."
CONTAINER_ID=$(docker run -d \
    --name mcp-devops-docker-test \
    --hostname=mcp-devops \
    --privileged \
    --cap-add=SYS_PTRACE \
    --security-opt seccomp=unconfined \
    --shm-size=2g \
    -v $(pwd):/workspace:cached \
    -v /var/run/docker.sock:/var/run/docker.sock \
    mcp-devops-docker-test:latest)

echo "Waiting for services to initialize..."
sleep 8

# Check s6 services
echo ""
echo "3. Checking s6 service status..."
docker exec mcp-devops-docker-test bash -c "ls -la /etc/s6-overlay/s6-rc.d/ | grep docker-fix" 2>/dev/null
if [ $? -eq 0 ]; then
    echo "✓ docker-fix service is configured"
else
    echo "✗ docker-fix service not found"
fi

# Check Docker socket inside container
echo ""
echo "4. Checking Docker socket visibility..."
OUTPUT=$(docker exec mcp-devops-docker-test ls -la /var/run/docker.sock 2>&1)
if [[ $OUTPUT == *"docker.sock"* ]]; then
    echo "✓ Docker socket is mounted"
    echo "  $OUTPUT"
else
    echo "✗ Docker socket not found"
fi

# Check Docker group configuration
echo ""
echo "5. Checking Docker group configuration..."
docker exec mcp-devops-docker-test bash -c "getent group | grep -E 'docker|docker-host'" 2>/dev/null
DOCKER_GID=$(docker exec mcp-devops-docker-test stat -c %g /var/run/docker.sock 2>/dev/null)
echo "Docker socket GID: $DOCKER_GID"

# Check jovian user groups
echo ""
echo "6. Checking jovian user groups..."
GROUPS=$(docker exec mcp-devops-docker-test id jovian 2>&1)
echo "$GROUPS"
if [[ $GROUPS == *"docker"* ]] || [[ $GROUPS == *"docker-host"* ]]; then
    echo "✓ jovian is in a Docker group"
else
    echo "✗ jovian is not in any Docker group"
fi

# Test Docker access as jovian without newgrp
echo ""
echo "7. Testing Docker access as jovian (direct)..."
OUTPUT=$(docker exec -u jovian mcp-devops-docker-test docker version --format 'Client: {{.Client.Version}}' 2>&1)
if [[ $OUTPUT == *"Client:"* ]]; then
    echo "✓ Direct Docker access works: $OUTPUT"
else
    echo "⚠ Direct access needs newgrp, trying with new session..."
    
    # Test with newgrp
    OUTPUT=$(docker exec -u jovian mcp-devops-docker-test bash -c "newgrp docker && docker version --format 'Client: {{.Client.Version}}'" 2>&1)
    if [[ $OUTPUT == *"Client:"* ]]; then
        echo "✓ Docker access works with newgrp: $OUTPUT"
    else
        echo "✗ Docker access failed: $OUTPUT"
    fi
fi

# Test actual Docker command
echo ""
echo "8. Testing Docker command execution..."
OUTPUT=$(docker exec -u jovian mcp-devops-docker-test bash -c "docker ps >/dev/null 2>&1 && echo 'success' || echo 'failed'" 2>&1)
if [[ $OUTPUT == "success" ]]; then
    echo "✓ Docker ps command works"
else
    # Try with group refresh
    OUTPUT=$(docker exec -u jovian mcp-devops-docker-test bash -c "newgrp docker && docker ps >/dev/null 2>&1 && echo 'success' || echo 'failed'" 2>&1)
    if [[ $OUTPUT == "success" ]]; then
        echo "✓ Docker ps works with newgrp"
    else
        echo "✗ Docker ps failed"
    fi
fi

# Check sync script logs
echo ""
echo "9. Checking Docker sync script output..."
echo "S6 logs:"
docker exec mcp-devops-docker-test bash -c "cat /var/log/s6-uncaught-logs/current 2>/dev/null | grep -E 'docker-fix|Docker|GID' | tail -30"
echo ""
echo "Manual sync test:"
docker exec mcp-devops-docker-test bash -c "/usr/local/bin/sync-docker-gid.sh" 2>&1 | head -30

# Cleanup
echo ""
echo "10. Cleaning up..."
docker stop mcp-devops-docker-test >/dev/null 2>&1
docker rm mcp-devops-docker-test >/dev/null 2>&1
echo "✓ Cleanup complete"

echo ""
echo "=== Summary ==="
echo "Docker permission sync has been implemented with:"
echo "- Automatic GID synchronization at startup via s6-overlay"
echo "- sync-docker-gid.sh script for manual sync"
echo "- Support for both docker and docker-host groups"
echo "- DevContainer postStartCommand integration"
echo ""
echo "Note: Users may need to run 'newgrp docker' in existing shells"
echo "after the container starts to refresh group membership."