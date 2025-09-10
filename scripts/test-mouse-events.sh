#!/bin/bash
# Test if mouse events are being received in Sway

echo "=== Testing Mouse Events in Sway ==="
echo ""

# Create a test script that logs mouse events
docker exec mcp-devops-dev bash -c 'cat > /tmp/mouse-logger.sh << "EOF"
#!/bin/bash
echo "$(date): $1" >> /tmp/mouse-events.log
/usr/local/bin/launcher.sh
EOF
chmod +x /tmp/mouse-logger.sh'

# Update Sway config to use the logger
docker exec mcp-devops-dev bash -c 'cat > /home/jovian/.config/sway/mouse-test.conf << "EOF"
# Simple mouse test config
# Test if any mouse button works
bindsym button1 exec /tmp/mouse-logger.sh "Left click"
bindsym button2 exec /tmp/mouse-logger.sh "Middle click"
bindsym button3 exec /tmp/mouse-logger.sh "Right click"

# Also test with --release
bindsym --release button3 exec /usr/local/bin/launcher.sh

# Test with modifier key
bindsym Mod4+button3 exec /usr/local/bin/launcher.sh
bindsym Ctrl+button3 exec /usr/local/bin/launcher.sh
EOF'

# Include the test config in main config
docker exec mcp-devops-dev bash -c 'echo "include /home/jovian/.config/sway/mouse-test.conf" >> /home/jovian/.config/sway/config'

# Reload Sway
docker exec mcp-devops-dev bash -c 'export SWAYSOCK=/tmp/runtime-jovian/$(ls /tmp/runtime-jovian | grep sway); swaymsg reload'

echo "Mouse test configuration loaded."
echo ""
echo "To test:"
echo "1. Connect with VNC (KRDC) to localhost:5900"
echo "2. Try clicking with different mouse buttons"
echo "3. Check logs with: docker exec mcp-devops-dev cat /tmp/mouse-events.log"
echo ""
echo "Also try:"
echo "- Right-click anywhere"
echo "- Ctrl+Right-click"
echo "- Super(Win)+Right-click"