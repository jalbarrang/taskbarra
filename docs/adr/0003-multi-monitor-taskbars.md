# ADR 0003: One taskbar per display

## Status

Accepted

## Context

Taskbarra originally owned one `NSPanel` positioned on `NSScreen.main`, showed every discovered window in that panel, reserved one work area, and hid the entire taskbar when the frontmost application was fullscreen. This model cannot represent a desktop with multiple independent displays.

macOS also exposes two coordinate systems that must not be mixed. `NSScreen.frame` and `NSWindow` use AppKit's global bottom-left origin, while `kCGWindowBounds`, `CGDisplayBounds`, and Accessibility window frames use a global top-left origin. The global conversion must flip against the primary display height; flipping inside each secondary display's local frame gives incorrect coordinates and can move a window onto the wrong monitor.

`NSScreen` object identity is not stable across display hotplug, sleep, or wake. Display ownership therefore needs a stable system identifier, and screen-parameter notifications must be treated as bursty intermediate state rather than a single atomic update.

## Options considered

### 1. Show every window on every taskbar

Rejected as the default because duplicate entries make it harder to see which display owns a window. This may become an explicit preference later.

### 2. Show each window only on its assigned display

Accepted. A window belongs to the display with the largest intersection area between its CoreGraphics bounds and `CGDisplayBounds`. Exact ties use the lower display ID for deterministic behavior. A minimized or stale window with no display intersection falls back to the primary display, defined by `NSScreen.screens[0]` rather than the focus-dependent `NSScreen.main`.

## Decision

- `MultiMonitorTaskbarCoordinator` owns one shared `WindowStore`, one shared `NotificationStore`, display reconciliation, per-display work areas, and fullscreen visibility.
- `TaskbarPanelController` owns one non-activating `NSPanel` for one `CGDirectDisplayID` and resolves the current `NSScreen` by that ID whenever it repositions.
- Mirrored replicas do not receive duplicate panels; the mirror source remains eligible.
- `WindowDisplayStore` computes one window-to-display assignment map per snapshot or display-topology change, then each `TaskbarView` renders only its display's IDs.
- `WorkAreaReservation` stores CoreGraphics-space screen and usable frames per display. `AXWindowWorkAreaCoordinator` resolves a window and its work area together before applying AX position or size, preventing cross-display frame application.
- Fullscreen coverage is evaluated per display. With separate Spaces enabled, only an occluded display's panel hides. When `NSScreen.screensHaveSeparateSpaces` is false, any fullscreen display hides all panels because native fullscreen blanks the other displays.
- `NSApplication.didChangeScreenParametersNotification` reconciliation is debounced by 250 milliseconds and is idempotent.

## Consequences

Taskbarra now creates and removes bars as physical displays appear and disappear, keeps scanning cost independent of display count, and preserves single-display behavior. Pure coordinate conversion, screen assignment, work-area pairing, and occlusion rules live in `TaskbarraCore` with unit tests.

Taskbarra still cannot register a public Dock-style system work area. It continues to resize maximized windows through Accessibility and uses Rectangle's global bottom gap when Rectangle is installed.

## Manual multi-display verification

The implementation builds and its automated tests pass, but the following hardware checks remain intentionally unclaimed until run on a Mac with multiple displays:

- [ ] Connect and disconnect an external display; its bar appears and disappears without restarting Taskbarra.
- [ ] Sleep and wake the Mac; each physical display has exactly one correctly positioned bar.
- [ ] Enable display mirroring; the mirrored pair shows one bar rather than duplicate overlapping bars.
- [ ] Drag a window between displays; its entry moves to the destination bar after the next snapshot refresh.
- [ ] Maximize a window on a secondary display; it stays on that display and stops above that display's bar.
- [ ] Enter fullscreen on one display with separate Spaces enabled; only that display's bar hides.
- [ ] Disable separate Spaces and enter fullscreen; all bars hide, then return when fullscreen exits.
- [ ] Run Rectangle and maximize on each display; the configured bottom gap remains at least Taskbarra's height.
