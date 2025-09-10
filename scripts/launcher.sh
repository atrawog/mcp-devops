#!/bin/bash
# App launcher script with filtered desktop entries

# Set environment to ONLY show our custom applications
# Remove /usr/share to exclude system applications
export XDG_DATA_DIRS=/home/jovian/.local/share
export XDG_DATA_HOME=/home/jovian/.local/share
export GTK_THEME=Adwaita
export GDK_PIXBUF_MODULE_FILE=/usr/lib/gdk-pixbuf-2.0/2.10.0/loaders.cache

# Launch wofi with drun mode and minimal styling
exec wofi --show drun --insensitive --no-actions