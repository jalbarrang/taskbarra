# Multi-monitor support for Taskbarra

## Goal

Taskbarra currently shows a single bar on the main screen (`CONTEXT.md` decision: "Monitores: una sola barra en el monitor principal"). Ship one bar per connected display, each showing only the windows on that display (Windows' "show taskbar buttons where the window is open" model — same as uBar / Taskbar for macOS / HammerBar).

## Current architecture (what you're changing)

All paths relative to repo root `/Users/jalbarran/fun/drekki/taskbarra`.

- `Sources/Taskbarra/TaskbarWindowController.swift` — god object: owns the single `NSPanel`, `WindowStore`, `NotificationStore`, `WorkAreaReservation`, `AXWindowWorkAreaCoordinator`, `RectangleCompatibilityCoordinator`, fullscreen polling, and placement. Multi-monitor requires splitting it.
- `Sources/Taskbarra/TaskbarGeometry.swift` — computes bar frame; only has `forMainScreen()`.
- `Sources/Taskbarra/WorkAreaReservation.swift` — single global screen/usable frame. **Contains a latent bug** (see Coordinate systems).
- `Sources/Taskbarra/AXWindowWorkAreaCoordinator.swift` — pushes maximized windows above the bar using ONE global `screenFrame`/`usableFrame`. `WindowFramePolicy` (in `Sources/TaskbarraCore/WindowFramePolicy.swift`) already takes frames per call, so the policy core is multi-monitor-ready.
- `Sources/Taskbarra/TaskbarPlacementObserver.swift` — already listens to `NSApplication.didChangeScreenParametersNotification` + space changes. Reuse as the reconcile trigger; debounce (it fires in bursts on hotplug/wake).
- `Sources/Taskbarra/AppCoordinator.swift` — creates the one `TaskbarWindowController` after permissions are granted.
- `Sources/TaskbarraCore/WindowScanner.swift`, `WindowInfo.swift` — window enumeration via `CGWindowListCopyWindowInfo`; `WindowInfo.bounds` is in **CG global coordinates** (top-left origin).
- `Sources/Taskbarra/WindowStore.swift` — observable store over scanner + passive AX scanner. Keep ONE shared store; bars filter it.
- `Sources/Taskbarra/RectangleCompatibilityCoordinator.swift` — sets Rectangle's global `screenEdgeGapBottom`. It is a single global value, which stays correct because every bar has the same height. No change needed.

## Coordinate systems (the core trap)

- **CG/AX global space** (`kCGWindowBounds`, AX positions, `CGDisplayBounds`): origin at **top-left of the primary display**, y grows downward.
- **AppKit space** (`NSScreen.frame`, `NSWindow.setFrame`): origin at **bottom-left of the primary display**, y grows upward.
- Correct conversion of an AppKit rect to CG global: `cgY = primaryScreenHeight - appKitRect.maxY` where `primaryScreenHeight = NSScreen.screens[0].frame.height` (the primary screen always has AppKit origin (0,0)). x and width/height are unchanged.
- **Existing bug**: `WorkAreaReservation.convertToWindowCoordinates` computes `screenFrame.minY + (screenFrame.maxY - frame.maxY)` — a flip within the screen's own frame. It coincidentally works for the primary screen (minY = 0) and is wrong for any secondary screen. Must be fixed before per-screen work areas.

## Design decisions (settled with user)

1. **Per-screen filtering** (Option A). Each bar shows only windows whose bounds intersect its display most. A "show all windows on every bar" toggle is explicitly out of scope (possible follow-up).
2. **Window→screen assignment**: largest intersection area between `WindowInfo.bounds` (CG space) and each screen's frame converted to CG space. Minimized windows (stale/no on-screen bounds from passive AX scan) → assign by their last-known bounds; if nothing intersects, fall back to the main screen's bar.
3. **Panels keyed by `CGDirectDisplayID`** (`screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID`), never by `NSScreen` object identity — screen objects churn on hotplug/sleep/wake.
4. **Mirrored displays**: skip screens whose display ID is in a mirror set (`CGDisplayIsInMirrorSet(id) && CGDisplayMirrorsDisplay(id) != kCGNullDirectDisplay`), else a duplicate bar appears on the mirror.
5. **Fullscreen hiding goes per-screen**: a display is occluded if any layer-0 window's CG bounds enclose `CGDisplayBounds(displayID)` within a small epsilon (~4pt), or a true AX-fullscreen window sits on that display. Hide only that display's bar. Exception: when `NSScreen.screensHaveSeparateSpaces == false`, native fullscreen blanks all other displays, so hide **all** bars if any display is fullscreen-occluded.
6. **One shared `WindowStore`/`NotificationStore`** owned above the panel controllers; per-bar filtering happens at view/controller level. Do not run N scanners.

## Execution notes

- Build/test gate for every task: `swift build && swift test` from repo root, exit 0.
- Pure logic (coordinate conversion, screen assignment, occlusion) goes in `Sources/TaskbarraCore/` with unit tests — the Tests target only covers TaskbarraCore. AppKit-touching glue stays in `Sources/Taskbarra/`.
- Tests use a hand-rolled runner: check `Tests/TaskbarraCoreTests/main.swift` and register new test entry points the same way existing tests do.
- Multi-monitor behavior cannot be verified in CI. Each task's gate is compile + unit tests; the final task defines the manual hardware checklist. STOP and report (do not guess) if a task requires observing real multi-display behavior to proceed.
- Keep `NSPanel` configuration (`TaskbarWindowConfigurator`) as-is: `.canJoinAllSpaces` etc. already handle Spaces correctly per screen.

## Risks

- Hotplug/wake races: `didChangeScreenParametersNotification` fires repeatedly with intermediate states; reconcile must be idempotent and debounced (~250ms).
- AX work-area moves on the wrong screen would be user-visible data loss (windows jumping displays). The per-screen `usableFrame` must be derived from the SAME screen the window was assigned to; add tests for the assignment→frame pairing.
- `NSScreen.main` is the screen with keyboard focus, NOT the primary display. Use `NSScreen.screens[0]` (or origin-(0,0) frame) when "primary" is meant.
