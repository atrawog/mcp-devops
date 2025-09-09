#!/bin/bash
# Test script to verify wofi is working

export XDG_RUNTIME_DIR=/tmp/runtime-jovian
export WAYLAND_DISPLAY=wayland-1

echo "Testing wofi launcher..."
echo "Available desktop entries:"
ls -la /home/jovian/.local/share/applications/

echo ""
echo "Testing wofi command:"
timeout 1 wofi --show drun --fork 2>&1 | head -5 || echo "Wofi test completed"