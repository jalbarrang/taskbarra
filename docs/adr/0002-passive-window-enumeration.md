# ADR 0002: Passive window enumeration boundary

## Status

Accepted

## Context

Taskbarra needs to discover and display windows without surprising the user by changing focus, raising windows, or activating apps. macOS offers multiple APIs with different side-effect profiles:

- CoreGraphics `CGWindowListCopyWindowInfo` reads WindowServer metadata and is the primary passive source for visible windows.
- Accessibility `AXUIElementCopyAttributeValue` can read app/window metadata without activation when used only for attributes and observers.
- Accessibility setters/actions and `NSRunningApplication.activate` are mutating interactions and must remain behind explicit user actions or clearly named coordinators.

## Current scan path audit

Normal monitoring starts in `MultiMonitorTaskbarCoordinator.start()`:

1. `WindowStore.startMonitoring()`
2. `WindowStore.refreshPassiveSnapshot()`
3. `WindowScanner.scanVisibleWindowsInStackingOrder()`
4. `CGWindowInfoProvider.copyWindowInfo(options:relativeToWindow:)`
5. `CGWindowListCopyWindowInfo(.optionOnScreenOnly + .excludeDesktopElements, kCGNullWindowID)`
6. `WindowScanner.parseWindowInfo` and relevance filtering
7. `WindowStore.enrichTitle` via `WindowTitleResolver.bestEffortTitle`
8. `AXWindowResolver.findWindow` only when the CoreGraphics title is empty
9. `PassiveAXWindowScanner.scanMinimizedWindows()` reads regular apps from `NSWorkspace.shared.runningApplications` and AX window attributes for minimized windows
10. `AXUIElementCopyAttributeValue` reads `kAXWindowsAttribute`, `kAXMinimizedAttribute`, `kAXPositionAttribute`, `kAXSizeAttribute`, and `kAXTitleAttribute`
11. `WindowStore.isFrontmostApplicationWindow` reads `NSWorkspace.shared.frontmostApplication`
12. `WindowSnapshotMatcher` correlates visible CoreGraphics windows with passive AX snapshots using PID, compatible titles, and tolerant frame comparison
13. `ApplicationIconProvider.icon(forOwnerPID:)` reads app icons through `NSRunningApplication`

This path does **not** call `NSRunningApplication.activate`, `AXUIElementPerformAction(kAXRaiseAction)`, or `AXUIElementSetAttributeValue` from the scanner/title/icon/active-window discovery code.

## Event monitoring audit

`AXWindowEventMonitor.start()` registers passive observers:

- workspace notifications from `NSWorkspace.shared.notificationCenter`
- per-app `AXObserver` instances
- AX notifications for window creation/focus/title/minimize/move/resize/destroy

It reads `kAXWindowsAttribute` to attach window observers. It does not activate, raise, focus, minimize, close, move, or resize windows.

## Explicit interaction path audit

`WindowInteractionController` owns user-triggered interactions:

- `toggle(window:isActive:)`
- `minimizeOrRestore(window:)`
- `close(window:)`
- `activate(window:)`
- `showAllWindows(forOwnerPID:)`
- `hideApplication(ownerPID:)`
- `quitApplication(ownerPID:)`
- `forceQuitApplication(ownerPID:)`
- `relaunchApplication(ownerPID:)`
- Finder/pasteboard helpers

Activation and raise are confined here:

- `NSRunningApplication.activate(options:)`
- `AXUIElementPerformAction(..., kAXRaiseAction)`

AX mutation is also confined here for close/minimize/restore, except for work-area management below.

## Known non-passive coordinator

`AXWindowWorkAreaCoordinator.reconcile(windows:)` is not discovery. It finds matching AX windows and can set `kAXPositionAttribute` / `kAXSizeAttribute` to reserve Taskbarra's work area for maximized windows. `MultiMonitorTaskbarCoordinator` invokes this layout phase from `WindowStore.onPassiveSnapshotDidChange`, keeping mutation explicit and separate from passive scanning.

This is an intentional layout-management side effect, but it must remain separate from window discovery contracts. `WindowStore` owns passive snapshots; `MultiMonitorTaskbarCoordinator` owns the decision to run layout reconciliation after a snapshot changes.

## Decision

- Window discovery APIs must stay read-only/passive.
- `WindowStore.refreshPassiveSnapshot()` and `WindowScanner` must not activate, raise, focus, minimize, close, move, or resize windows.
- AX attribute reads are allowed for passive enrichment and minimized-window discovery.
- User actions remain in `WindowInteractionController`.
- Layout mutation remains in `AXWindowWorkAreaCoordinator` and must not be presented as scanning/discovery.

## Consequences

The next implementation steps are:

1. Make the discovery vs interaction/layout contracts explicit in names and wiring.
2. Keep documentation updated with macOS limitations and permission implications.
