# Right-Click Launcher Configuration

## Current Status
The right-click launcher has been configured with multiple binding approaches to ensure maximum compatibility with VNC clients.

## Configuration Details

### Sway Mouse Bindings
```
# Primary binding - button code 273 (right mouse button)
bindcode 273 exec /usr/local/bin/launcher.sh

# Window-specific bindings
bindsym --whole-window button3 exec /usr/local/bin/launcher.sh
bindsym --whole-window --border button3 exec /usr/local/bin/launcher.sh  
bindsym --whole-window --titlebar button3 exec /usr/local/bin/launcher.sh

# Modifier key fallbacks
bindsym Mod4+button3 exec /usr/local/bin/launcher.sh  # Super+Right-click
bindsym Mod1+button3 exec /usr/local/bin/launcher.sh  # Alt+Right-click
```

### Launcher Script
Located at `/usr/local/bin/launcher.sh`:
- Filters desktop entries to show only Terminal and Chrome
- Sets proper environment variables for Wayland/GTK
- Launches wofi in drun mode

### Desktop Entries
Only two applications are available:
- `foot.desktop` - Terminal
- `google-chrome.desktop` - Google Chrome

## Testing the Launcher

### Via Keyboard (Works)
- Press `Mod4+d` (Super/Windows key + D)
- The launcher should appear showing Terminal and Chrome

### Via Mouse (Troubleshooting)
Due to VNC/Wayland interaction limitations, right-click bindings may not work as expected.

#### Alternative Methods:
1. **Alt+Right-click**: Hold Alt and right-click anywhere
2. **Super+Right-click**: Hold Super/Windows key and right-click
3. **Keyboard shortcut**: Use Mod4+d instead

## Known Issues

### VNC Mouse Event Passthrough
- wayvnc creates a virtual pointer device (`wlr_virtual_pointer_v1`)
- Mouse button events may not be correctly passed to Sway bindings
- This is a known limitation of VNC with Wayland compositors

### Workarounds
1. Use keyboard shortcuts (Mod4+d) for reliable launcher access
2. Use modifier keys with mouse clicks (Alt+Right-click)
3. Keep Terminal and Chrome windows open to avoid needing the launcher

## Debug Commands

```bash
# Test launcher directly
docker exec mcp-devops-dev /usr/local/bin/launcher.sh

# Check if wofi is running
docker exec mcp-devops-dev pgrep -a wofi

# Test via swaymsg
docker exec mcp-devops-dev bash -c 'export SWAYSOCK=/tmp/runtime-jovian/$(ls /tmp/runtime-jovian | grep sway); swaymsg exec /usr/local/bin/launcher.sh'

# Check Sway input devices
docker exec mcp-devops-dev bash -c 'export SWAYSOCK=/tmp/runtime-jovian/$(ls /tmp/runtime-jovian | grep sway); swaymsg -t get_seats'
```

## Recommendations

For the most reliable experience:
1. Keep Terminal and Chrome windows open and use Alt+Tab to switch
2. Use keyboard shortcuts (Mod4+d) to open the launcher
3. Consider using a different VNC client that better supports mouse events
4. Use SSH with X11 forwarding as an alternative to VNC