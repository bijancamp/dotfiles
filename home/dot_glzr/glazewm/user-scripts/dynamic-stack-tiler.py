"""
Tries to emulate dwm-style dynamic tiling. In dwm's tiled layout mode, all new
non-master windows are vertically added to the stack, regardless of which window
is focused.

However, since I do not know how to replicate this behavior exactly with
GlazeWM's i3-style tiling, I have settled for the following approach:

1) The first two windows added to a workspace are tiled horizontally.
2) Assuming no windows get closed, all additional windows are tiled vertically.

This is achieved by setting the tiling direction of windows when focusing them.
If the focused window has a width that is less than the width of the display,
its tiling direction is set to "vertical"; otherwise, it is set to "horizontal".

This means you can add "secondary" master windows to the left-hand column, which
I'm not super enthusiastic about, but it might be useful in certain situations.

Additionally, if enough windows are closed such that you have a "rows" layout
with multiple windows stacked on top of each other, then any new window you add
to one of the rows will be tiled vertically, since each of the "row" windows
will span the entire width of the display and thus have their tiling direction
set to "vertical".

Inspired by: https://github.com/glzr-io/glazewm/discussions/66#discussioncomment-10838322
"""

import asyncio
import json
import ctypes
from ctypes import wintypes
import websockets
from websockets.exceptions import ConnectionClosed

WS_URI = "ws://localhost:6123"


# Make the process DPI-aware so pixel sizes match reality on HiDPI displays
try:
    ctypes.windll.user32.SetProcessDPIAware()
except Exception:
    pass  # older Windows: ignore if not available

class RECT(ctypes.Structure):
    _fields_ = [
        ("left",   wintypes.LONG),
        ("top",    wintypes.LONG),
        ("right",  wintypes.LONG),
        ("bottom", wintypes.LONG),
    ]

class MONITORINFO(ctypes.Structure):
    _fields_ = [
        ("cbSize",    wintypes.DWORD),
        ("rcMonitor", RECT),
        ("rcWork",    RECT),
        ("dwFlags",   wintypes.DWORD),
    ]

_user32 = ctypes.windll.user32

def _primary_monitor_width() -> int:
    # SM_CXSCREEN = 0
    return _user32.GetSystemMetrics(0)

def get_active_monitor_width() -> int:
    """Returns the width (in pixels) of the monitor of the foreground window."""
    hwnd = _user32.GetForegroundWindow()

    if not hwnd:
        return _primary_monitor_width()

    # MONITOR_DEFAULTTONEAREST = 2
    hmon = _user32.MonitorFromWindow(hwnd, 2)

    if not hmon:
        return _primary_monitor_width()

    mi = MONITORINFO()
    mi.cbSize = ctypes.sizeof(MONITORINFO)

    if not _user32.GetMonitorInfoW(hmon, ctypes.byref(mi)):
        return _primary_monitor_width()

    return int(mi.rcMonitor.right - mi.rcMonitor.left)

async def main():
    async with websockets.connect(WS_URI) as websocket:
        await websocket.send("sub -e focus_changed")

        while True:
            try:
                response = await websocket.recv()
            except ConnectionClosed:
                print("GlazeWM websocket closed--exiting.")
                return

            try:
                width_val = json.loads(response)["data"]["focusedContainer"]["width"]
            except (KeyError, json.JSONDecodeError):
                continue

            try:
                focused_container_width = float(width_val)
            except (TypeError, ValueError):
                print(f"Warning: width is missing or not numeric in response: {response}")
                continue

            monitor_width = float(get_active_monitor_width())
            direction = "horizontal" if focused_container_width == monitor_width else "vertical"

            await websocket.send(f"command set-tiling-direction {direction}")

if __name__ == "__main__":
    asyncio.run(main())
