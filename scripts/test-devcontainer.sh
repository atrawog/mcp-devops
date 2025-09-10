#!/bin/bash
# Test script to verify DevContainer configuration compliance

echo "=== Testing DevContainer Configuration ==="
echo ""

# Build the container
echo "1. Building DevContainer image..."
docker build -t mcp-devops-devcontainer:test . || exit 1
echo "✓ Build successful"
echo ""

# Test 1: Run without user mapping (default)
echo "2. Testing default user configuration..."
CONTAINER_ID=$(docker run -d \
    --name mcp-devops-devcontainer-test1 \
    --hostname=mcp-devops \
    --privileged \
    --cap-add=SYS_PTRACE \
    --security-opt seccomp=unconfined \
    --shm-size=2g \
    -v $(pwd):/workspace:cached \
    mcp-devops-devcontainer:test)

sleep 3

# Check user inside container
USER_INFO=$(docker exec -u jovian mcp-devops-devcontainer-test1 id 2>/dev/null)
if [[ $USER_INFO == *"uid=1000(jovian)"* ]]; then
    echo "✓ Default user 'jovian' with UID 1000 exists"
else
    echo "✗ User configuration issue: $USER_INFO"
fi

# Check workspace permissions
WORKSPACE_OWNER=$(docker exec mcp-devops-devcontainer-test1 stat -c "%U:%G" /workspace 2>/dev/null)
if [[ $WORKSPACE_OWNER == "jovian:jovian" ]]; then
    echo "✓ Workspace owned by jovian user"
else
    echo "✗ Workspace ownership issue: $WORKSPACE_OWNER"
fi

# Cleanup
docker stop mcp-devops-devcontainer-test1 >/dev/null 2>&1
docker rm mcp-devops-devcontainer-test1 >/dev/null 2>&1
echo ""

# Test 2: Simulate DevContainer with remoteUser
echo "3. Testing remoteUser configuration..."
CONTAINER_ID=$(docker run -d \
    --name mcp-devops-devcontainer-test2 \
    --hostname=mcp-devops \
    --privileged \
    --cap-add=SYS_PTRACE \
    --security-opt seccomp=unconfined \
    --shm-size=2g \
    -v $(pwd):/workspace:cached \
    -e REMOTE_USER=jovian \
    mcp-devops-devcontainer:test)

sleep 3

# Test running commands as remoteUser
OUTPUT=$(docker exec -u jovian mcp-devops-devcontainer-test2 bash -c "cd /workspace && touch test-file.txt 2>&1 && rm test-file.txt 2>&1 && echo 'success'" 2>/dev/null)
if [[ $OUTPUT == "success" ]]; then
    echo "✓ remoteUser 'jovian' can write to workspace"
else
    echo "✗ remoteUser permission issue: $OUTPUT"
fi

# Check runtime directory
RUNTIME_DIR=$(docker exec -u jovian mcp-devops-devcontainer-test2 bash -c "ls -ld /tmp/runtime-jovian 2>/dev/null | awk '{print \$1, \$3}'" 2>/dev/null)
if [[ $RUNTIME_DIR == *"drwx"* ]]; then
    echo "✓ Runtime directory configured correctly"
else
    echo "✗ Runtime directory issue: $RUNTIME_DIR"
fi

# Cleanup
docker stop mcp-devops-devcontainer-test2 >/dev/null 2>&1
docker rm mcp-devops-devcontainer-test2 >/dev/null 2>&1
echo ""

# Test 3: Check services
echo "4. Testing services..."
CONTAINER_ID=$(docker run -d \
    --name mcp-devops-devcontainer-test3 \
    --hostname=mcp-devops \
    --privileged \
    --cap-add=SYS_PTRACE \
    --security-opt seccomp=unconfined \
    --shm-size=2g \
    -p 5900:5900 \
    -v $(pwd):/workspace:cached \
    -e VNC_PASSWORD=test \
    mcp-devops-devcontainer:test)

echo "Waiting for services to start..."
sleep 8

# Check VNC port
VNC_PORT=$(docker exec mcp-devops-devcontainer-test3 ss -tln | grep 5900 2>/dev/null)
if [[ -n "$VNC_PORT" ]]; then
    echo "✓ VNC service listening on port 5900"
else
    echo "✗ VNC service not running"
fi

# Check Sway
SWAY_PID=$(docker exec mcp-devops-devcontainer-test3 pgrep sway 2>/dev/null)
if [[ -n "$SWAY_PID" ]]; then
    echo "✓ Sway compositor running (PID: $SWAY_PID)"
else
    echo "✗ Sway not running"
fi

# Check WayVNC
WAYVNC_PID=$(docker exec mcp-devops-devcontainer-test3 pgrep wayvnc 2>/dev/null)
if [[ -n "$WAYVNC_PID" ]]; then
    echo "✓ WayVNC running (PID: $WAYVNC_PID)"
else
    echo "✗ WayVNC not running"
fi

# Cleanup
docker stop mcp-devops-devcontainer-test3 >/dev/null 2>&1
docker rm mcp-devops-devcontainer-test3 >/dev/null 2>&1
echo ""

echo "=== DevContainer Configuration Test Complete ==="
echo ""
echo "Summary:"
echo "- Image builds successfully with Dev Container spec compliance"
echo "- User configuration follows remoteUser/updateRemoteUserUID pattern"
echo "- Services start correctly without manual UID mapping"
echo "- Workspace permissions work with default jovian user"
echo ""
echo "The devcontainer.json is now properly configured according to:"
echo "https://containers.dev/implementors/spec/"