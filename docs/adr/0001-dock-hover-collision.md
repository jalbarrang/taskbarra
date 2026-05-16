# ADR 0001: Dock hover collision while Taskbarra is open

## Status

Accepted

## Context

Taskbarra currently lives on the bottom screen edge and is always visible. When the user keeps the native macOS Dock on the same edge with auto-hide enabled, moving the pointer near the bottom edge can still trigger the Dock. The Dock may then appear over or near Taskbarra and interrupt normal taskbar usage.

This is not caused by Taskbarra's SwiftUI content. It is a system-level edge gesture owned by Dock.app / WindowServer. A normal `NSPanel`, even at a high window level, should not be treated as a reliable way to intercept or disable that system hover trigger.

## Options considered

### 1. Block the Dock hover directly

Rejected.

Taskbarra should not try to globally disable the Dock hover by killing Dock.app, rewriting user defaults at runtime, or relying on private APIs. Those approaches are brittle, surprising to users, and can leave global Dock settings changed after a crash.

`NSApplication.presentationOptions` such as hiding the Dock are also not a good fit for Taskbarra's main window because Taskbarra is a non-activating accessory-like panel. The active foreground app changes frequently, so presentation options would not be a stable global Dock suppression mechanism.

### 2. Add an invisible edge shield window

Rejected for now.

A transparent high-level window at the bottom edge might look like it blocks hover, but the Dock edge trigger is not guaranteed to respect app windows. It also risks stealing pointer events, breaking clicks/dragging near the edge, and creating confusing behavior across Spaces, full-screen apps, and multiple displays.

### 3. Move the native Dock away from Taskbarra's edge

Accepted as the recommended near-term workaround.

If the user wants Taskbarra on the bottom edge, the native Dock should be moved to the left or right edge, or hidden with a long auto-hide delay by the user. This avoids overlapping two launcher/task-switcher surfaces on the same edge without Taskbarra mutating global system preferences.

### 4. Make Taskbarra placement configurable

Accepted as the product direction.

Taskbarra should eventually support a configurable placement, starting with bottom and top. If the user wants to keep the macOS Dock at the bottom, Taskbarra can move to the top or another supported edge instead of fighting the Dock hover trigger.

## Decision

Do not implement automatic Dock-hover blocking in Taskbarra.

For the current prototype:

- Keep Taskbarra bottom-aligned by default.
- Document that the macOS Dock should be moved to left/right when both Dock auto-hide and bottom Taskbarra are used.
- Track follow-up implementation for configurable Taskbarra placement instead of attempting private/system-level Dock suppression.

## Consequences

- Taskbarra avoids changing global Dock preferences behind the user's back.
- Users retain control of the native Dock location and auto-hide behavior.
- Bottom Taskbarra + bottom auto-hidden Dock remains a known collision until placement configuration exists.
- Future implementation should focus on first-class placement settings and corresponding work-area reservation updates.

## Follow-up implementation notes

A placement feature should update all geometry users together:

- `TaskbarGeometry.taskbarFrame`
- `TaskbarGeometry.usableFrameAboveTaskbar` or a generalized usable-frame property
- `WorkAreaReservation`
- `AXWindowWorkAreaCoordinator`
- Rectangle compatibility gap handling
- Tests in `Tests/TaskbarraCoreTests`

A possible first version is an enum like:

```swift
enum TaskbarPlacement: String {
    case bottom
    case top
}
```

Then `TaskbarGeometry` can compute both `taskbarFrame` and `usableFrame` from placement. Left/right placement should be treated as a later design step because it changes the layout model more substantially.
