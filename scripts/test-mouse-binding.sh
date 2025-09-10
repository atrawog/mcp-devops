#!/bin/bash
# Test script to verify mouse bindings are working

echo "=== Testing Mouse Bindings with New Configuration ==="
echo ""

# Create a simple click logger
docker exec mcp-devops-dev bash -c 'cat > /tmp/log-click.sh << "EOF"
#!/bin/bash
echo "$(date): Mouse click detected - button3" >> /tmp/mouse-events.log
/usr/local/bin/launcher-strict.sh
EOF
chmod +x /tmp/log-click.sh'

# Test binding with swaymsg
echo "1. Adding test binding..."
docker exec mcp-devops-dev bash -c 'export SWAYSOCK=/tmp/runtime-jovian/$(ls /tmp/runtime-jovian | grep sway-ipc* | head -1); 
swaymsg "bindsym button3 exec /tmp/log-click.sh"' 2>&1

echo ""
echo "2. Checking current seat configuration..."
docker exec mcp-devops-dev bash -c 'export SWAYSOCK=/tmp/runtime-jovian/$(ls /tmp/runtime-jovian | grep sway-ipc* | head -1); 
swaymsg -t get_seats | grep -A5 "name"' 2>/dev/null | head -10

echo ""
echo "3. Checking if VNC client is connected..."
docker exec mcp-devops-dev ss -tn | grep :5900

echo ""
echo "=== TEST INSTRUCTIONS ==="
echo "1. Connect with KRDC to localhost:5900"
echo "2. Right-click anywhere on the desktop"
echo "3. Check if launcher appears or if events are logged:"
echo ""
echo "To check logs, run:"
echo "  docker exec mcp-devops-dev cat /tmp/mouse-events.log"
echo ""
echo "To monitor bindings in real-time:"
echo "  docker exec mcp-devops-dev bash -c 'export SWAYSOCK=/tmp/runtime-jovian/\$(ls /tmp/runtime-jovian | grep sway-ipc* | head -1); swaymsg -t subscribe -m \"[\\\"binding\\\"]\"'"