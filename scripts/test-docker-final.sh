#!/bin/bash
# Final test to verify Docker permissions work correctly

echo "=== Final Docker Permissions Test ==="
echo ""

# Build container
echo "Building container..."
docker build -t mcp-devops-final:latest . --quiet || exit 1

# Run container
echo "Starting container..."
CID=$(docker run -d \
    --name mcp-devops-final \
    --privileged \
    -v /var/run/docker.sock:/var/run/docker.sock \
    mcp-devops-final:latest)

# Wait for initialization
echo "Waiting for services to initialize..."
sleep 10

# Test 1: Check if sync ran
echo ""
echo "1. Checking if Docker sync ran at startup:"
docker exec mcp-devops-final cat /var/log/s6-uncaught-logs/current 2>/dev/null | grep -E "docker-fix|Docker|GID" | tail -10
if [ $? -ne 0 ]; then
    echo "No s6 logs found, checking alternative logs..."
    docker logs mcp-devops-final 2>&1 | grep -E "docker-fix|Docker|GID" | tail -10
fi

# Test 2: Check groups
echo ""
echo "2. Checking Docker groups:"
docker exec mcp-devops-final getent group | grep -E "^docker"

# Test 3: Check jovian membership
echo ""
echo "3. Checking jovian user:"
docker exec mcp-devops-final id jovian

# Test 4: Test Docker access with fresh session
echo ""
echo "4. Testing Docker access (with fresh session):"
docker exec -u jovian mcp-devops-final bash -c "docker version --format 'Docker {{.Client.Version}}' 2>&1" | head -1

# Test 5: Test with su to get fresh groups
echo ""
echo "5. Testing Docker with su (fresh groups):"
docker exec mcp-devops-final su - jovian -c "docker ps >/dev/null 2>&1 && echo '✓ Docker works' || echo '✗ Docker failed'"

# Test 6: Check socket permissions
echo ""
echo "6. Docker socket permissions:"
docker exec mcp-devops-final ls -la /var/run/docker.sock

# Cleanup
echo ""
echo "Cleaning up..."
docker stop mcp-devops-final >/dev/null 2>&1
docker rm mcp-devops-final >/dev/null 2>&1

echo ""
echo "=== Test Complete ==="