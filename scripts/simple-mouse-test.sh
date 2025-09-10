#!/bin/bash
# Simple mouse event test script

echo "$(date): Mouse button3 clicked!" >> /tmp/mouse-clicks.log
notify-send "Right Click Detected" 2>/dev/null || echo "Right click detected" >> /tmp/mouse-clicks.log