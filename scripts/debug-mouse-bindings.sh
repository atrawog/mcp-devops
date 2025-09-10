#!/bin/bash
# Debug mouse bindings in Sway

echo "=== Mouse Binding Debug ==="
echo ""

echo "1. Current mouse bindings in config:"
docker exec mcp-devops-dev grep -n "button3\|273" /home/jovian/.config/sway/config
echo ""

echo "2. Test if launcher script works directly:"
docker exec mcp-devops-dev bash -c '/usr/local/bin/launcher-strict.sh &' 2>&1 | head -5 || echo "Script test complete"
sleep 1
docker exec mcp-devops-dev pkill wofi 2>/dev/null
echo ""

echo "3. Create test binding with logging:"
docker exec mcp-devops-dev bash -c 'cat > /tmp/test-mouse.sh << "EOF"
#!/bin/bash
echo "$(date): Mouse event triggered - $1" >> /tmp/mouse-test.log
/usr/local/bin/launcher-strict.sh
EOF
chmod +x /tmp/test-mouse.sh'

echo "4. Add test binding to Sway:"
docker exec mcp-devops-dev bash -c 'export SWAYSOCK=/tmp/runtime-jovian/$(ls /tmp/runtime-jovian | grep sway); 
swaymsg "bindsym button3 exec /tmp/test-mouse.sh right-click"
swaymsg "bindsym --whole-window button3 exec /tmp/test-mouse.sh window-right-click"
swaymsg "bindsym --release button3 exec /tmp/test-mouse.sh release-right-click"'

echo ""
echo "5. Check seat capabilities:"
docker exec mcp-devops-dev bash -c 'export SWAYSOCK=/tmp/runtime-jovian/$(ls /tmp/runtime-jovian | grep sway); swaymsg -t get_seats | grep -A2 "capabilities"'

echo ""
echo "=== TEST INSTRUCTIONS ==="
echo "1. Connect via VNC (KRDC) to localhost:5900"
echo "2. Try right-clicking on the desktop"
echo "3. Try Alt+Right-click"
echo "4. Try Super+Right-click"
echo "5. Check if events were logged:"
echo "   docker exec mcp-devops-dev cat /tmp/mouse-test.log"
echo ""
echo "If no events are logged, it means VNC is not passing mouse events to Sway."