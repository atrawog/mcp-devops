# Mouse Binding Status Report

## Issue Summary
Direct right-click binding for the launcher is not working through VNC due to fundamental limitations in how VNC passes mouse events to Wayland compositors.

## Technical Background

### The Problem Chain
1. **KRDC (VNC Client)** → sends mouse events to →
2. **wayvnc (VNC Server)** → creates virtual pointer device →
3. **wlr_virtual_pointer_v1** → sends events to →
4. **Sway (Wayland Compositor)** → attempts to match bindings

### Why It Fails
- VNC creates a virtual pointer device (`wlr_virtual_pointer_v1`)
- This virtual device doesn't properly trigger root window mouse bindings in Sway
- The events are consumed by the window management layer before reaching the binding system
- This is a known limitation of VNC with Wayland compositors

## Current Configuration

```sway
# Mouse bindings in /home/jovian/.config/sway/config
floating_modifier Mod4

# Primary: Alt+Right-click (most reliable through VNC)
bindsym Mod1+button3 exec /usr/local/bin/launcher-strict.sh

# Secondary: Super+Right-click  
bindsym Mod4+button3 exec /usr/local/bin/launcher-strict.sh

# Direct bindings (don't work with VNC)
bindsym button3 exec /usr/local/bin/launcher-strict.sh
bindsym --release button3 exec /usr/local/bin/launcher-strict.sh
bindcode 273 exec /usr/local/bin/launcher-strict.sh
```

## What Works ✅

| Method | Command | Status | Notes |
|--------|---------|--------|-------|
| Keyboard | `Mod4+d` | ✅ Works | Most reliable method |
| Keyboard | `Mod4+c` | ✅ Works | Direct Chrome launch |
| Alt+Right-click | `Mod1+button3` | ⚠️ May work | Hold Alt, then right-click |
| Super+Right-click | `Mod4+button3` | ⚠️ May work | Hold Windows key, then right-click |

## What Doesn't Work ❌

| Method | Reason |
|--------|--------|
| Direct right-click | VNC doesn't pass root window mouse events to Sway |
| `--whole-window button3` | Window context not properly detected through VNC |
| `bindcode 273` | Raw button codes not passed through VNC layer |

## Recommended Workarounds

### 1. Primary Method: Keyboard Shortcut
```bash
Mod4+d  # Opens launcher showing Terminal and Chrome
```

### 2. Alternative: Modifier + Click
```bash
Alt+Right-click     # May work depending on VNC client
Super+Right-click   # May work depending on VNC client
```

### 3. Direct Application Launch
```bash
Mod4+Return  # Open Terminal
Mod4+c       # Open Chrome
```

## Testing Commands

```bash
# Check if mouse events are being logged
docker exec mcp-devops-dev cat /tmp/mouse-clicks.log

# Test launcher directly
docker exec mcp-devops-dev /usr/local/bin/launcher-strict.sh

# Check Sway input devices
docker exec mcp-devops-dev bash -c 'export SWAYSOCK=/tmp/runtime-jovian/$(ls /tmp/runtime-jovian | grep sway); swaymsg -t get_inputs'

# Monitor Sway events
docker exec mcp-devops-dev bash -c 'export SWAYSOCK=/tmp/runtime-jovian/$(ls /tmp/runtime-jovian | grep sway); swaymsg -t subscribe -m "[\\"binding\\"]"'
```

## Alternative Solutions

### 1. Use SSH with X11 Forwarding
Instead of VNC, use SSH with X11 forwarding for better input device support:
```bash
ssh -X user@host
```

### 2. Use a Different VNC Implementation
Some VNC servers handle mouse events differently. Options:
- TigerVNC
- x11vnc (requires X11, not pure Wayland)

### 3. Use a Wayland-native Remote Desktop
- RDP with wlroots-based implementations
- Waypipe for Wayland forwarding

## Conclusion

The right-click launcher binding limitation is a fundamental issue with VNC and Wayland interaction, not a configuration problem. The keyboard shortcuts (`Mod4+d`) provide a reliable alternative that works consistently.

For users who absolutely need mouse-based launching:
1. Use `Alt+Right-click` which may work depending on the VNC client
2. Keep Terminal window open and use it to launch applications
3. Consider using a taskbar/dock application that works better with VNC

## References
- [Sway Issue #4799](https://github.com/swaywm/sway/issues/4799) - Mouse bindings with VNC
- [wayvnc Issue #89](https://github.com/any1/wayvnc/issues/89) - Virtual pointer limitations
- [wlroots Virtual Pointer Protocol](https://wayland.app/protocols/wlr-virtual-pointer-unstable-v1)