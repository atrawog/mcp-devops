#!/bin/bash
# Wrapper script for launcher that ensures it runs in the correct environment

# Set up environment
export XDG_RUNTIME_DIR=/tmp/runtime-jovian
export WAYLAND_DISPLAY=wayland-1
export XDG_DATA_DIRS=/home/jovian/.local/share:/usr/share
export XDG_DATA_HOME=/home/jovian/.local/share
export GTK_THEME=Adwaita
export GDK_PIXBUF_MODULE_FILE=/usr/lib/gdk-pixbuf-2.0/2.10.0/loaders.cache

# Log the attempt
echo "$(date): Launcher triggered" >> /tmp/launcher.log

# Kill any existing wofi instance
pkill wofi 2>/dev/null

# Launch wofi
exec wofi --show drun --insensitive --no-actions