#!/bin/bash
# Strict launcher that only shows Terminal and Chrome

# Set up Wayland environment
export XDG_RUNTIME_DIR=/tmp/runtime-jovian
export WAYLAND_DISPLAY=wayland-1

# Create a temporary directory for our filtered desktop files
TEMP_DIR="/tmp/launcher-apps-$$"
mkdir -p "$TEMP_DIR/applications"
mkdir -p "$TEMP_DIR/pixmaps"

# Copy only the desktop files we want
cp /home/jovian/.local/share/applications/foot.desktop "$TEMP_DIR/applications/" 2>/dev/null
cp /home/jovian/.local/share/applications/google-chrome.desktop "$TEMP_DIR/applications/" 2>/dev/null

# Set environment to use only our temporary directory with fallback to system for libraries
export XDG_DATA_DIRS="$TEMP_DIR:/usr/share"
export XDG_DATA_HOME="$TEMP_DIR"
export GTK_THEME=Adwaita
export GDK_PIXBUF_MODULE_FILE=/usr/lib/gdk-pixbuf-2.0/2.10.0/loaders.cache

# Update the loader cache if needed
gdk-pixbuf-query-loaders --update-cache 2>/dev/null || true

# Launch wofi with simpler options
exec wofi --show drun --no-actions --allow-images

# Note: exec replaces the script, so cleanup won't run
# If we need cleanup, remove exec and add cleanup after wofi