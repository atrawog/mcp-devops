#!/bin/bash
# Debug mouse bindings in Sway

echo "=== Debugging Mouse Bindings ==="
echo ""

echo "1. Current Sway config mouse bindings:"
docker exec mcp-devops-dev grep -n "button" /home/jovian/.config/sway/config
echo ""

echo "2. Testing all mouse button bindings:"
docker exec mcp-devops-dev bash -c 'cat > /tmp/test-buttons.conf << EOF
# Test all mouse buttons
bindsym --release button1 exec echo "Left click detected" > /tmp/mouse-test.log
bindsym --release button2 exec echo "Middle click detected" > /tmp/mouse-test.log  
bindsym --release button3 exec echo "Right click detected" > /tmp/mouse-test.log
bindsym --whole-window --release button3 exec /usr/local/bin/launcher.sh
EOF'

echo "3. Get current Sway bindings:"
docker exec mcp-devops-dev bash -c 'export SWAYSOCK=/tmp/runtime-jovian/$(ls /tmp/runtime-jovian | grep sway); swaymsg -t get_bindings | grep button'
echo ""

echo "4. Testing keyboard shortcut (Mod4+d):"
docker exec mcp-devops-dev bash -c 'export SWAYSOCK=/tmp/runtime-jovian/$(ls /tmp/runtime-jovian | grep sway); swaymsg "exec /usr/local/bin/launcher.sh"'
sleep 1
if docker exec mcp-devops-dev pgrep wofi > /dev/null; then
    echo "✓ Launcher works via keyboard shortcut"
    docker exec mcp-devops-dev pkill wofi
else
    echo "✗ Launcher not working"
fi
echo ""

echo "5. Checking Sway seat configuration:"
docker exec mcp-devops-dev bash -c 'export SWAYSOCK=/tmp/runtime-jovian/$(ls /tmp/runtime-jovian | grep sway); swaymsg -t get_seats'