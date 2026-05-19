# Start Prompt: Single Window Activate on Click

## Goal
When clicking a window button in the taskbar, only bring **that specific window** to the front — not all windows of the same application.

## Codebase Context

**File to modify**: `Sources/Taskbarra/WindowInteractionController.swift`

This file has a private method:

```swift
private func activateApplication(ownerPID: pid_t) {
    NSRunningApplication(processIdentifier: ownerPID)?.activate(options: [.activateAllWindows])
}
```

This is called by:
- `toggle(window:isActive:)` — left-click handler
- `activate(window:)` — context menu "activate window"  
- `minimizeOrRestore(window:)` — minimize/restore action
- `showAllWindows(forOwnerPID:)` — context menu "show all windows"

The `.activateAllWindows` option causes ALL app windows to come forward. The `raise(axWindow)` call that follows targets the specific window via AXRaiseAction, but the damage is already done — all sibling windows are raised too.

## Steps

### Step 1: Add a single-window activation method
In `WindowInteractionController.swift`, add a new private method alongside the existing `activateApplication`:

```swift
private func activateApplicationForSingleWindow(ownerPID: pid_t) {
    NSRunningApplication(processIdentifier: ownerPID)?.activate()
}
```

Using `activate()` with no options (or `activate(options: [])`) makes the app frontmost without raising all its windows. The subsequent `raise(axWindow)` will bring only the targeted window to the front.

[DONE:1]

### Step 2: Update `toggle(window:isActive:)` to use single-window activation
Change the call from `activateApplication(ownerPID:)` to `activateApplicationForSingleWindow(ownerPID:)`:

```swift
func toggle(window: WindowInfo, isActive: Bool) {
    guard let axWindow = resolver.findWindow(matching: window, includeMinimized: true) else { return }

    if isActive && !resolver.isMinimized(axWindow) {
        minimize(axWindow)
        refreshWindows()
        return
    }

    restoreIfNeeded(axWindow)
    activateApplicationForSingleWindow(ownerPID: window.ownerPID)  // <-- changed
    raise(axWindow)
    refreshWindows()
}
```

[DONE:2]

### Step 3: Update `activate(window:)` to use single-window activation

```swift
func activate(window: WindowInfo) {
    guard let axWindow = resolver.findWindow(matching: window, includeMinimized: true) else { return }
    restoreIfNeeded(axWindow)
    activateApplicationForSingleWindow(ownerPID: window.ownerPID)  // <-- changed
    raise(axWindow)
    refreshWindows()
}
```

[DONE:3]

### Step 4: Update `minimizeOrRestore(window:)` to use single-window activation

```swift
func minimizeOrRestore(window: WindowInfo) {
    guard let axWindow = resolver.findWindow(matching: window, includeMinimized: true) else { return }

    if resolver.isMinimized(axWindow) {
        restoreIfNeeded(axWindow)
        activateApplicationForSingleWindow(ownerPID: window.ownerPID)  // <-- changed
        raise(axWindow)
    } else {
        minimize(axWindow)
    }
    refreshWindows()
}
```

[DONE:4]

### Step 5: Keep `showAllWindows` using `.activateAllWindows`
Verify that `showAllWindows(forOwnerPID:)` still calls the original `activateApplication(ownerPID:)` which uses `.activateAllWindows`. **No change needed** — just confirm it's untouched.

[DONE:5]

### Step 6: Build and verify
Run `swift build` to ensure compilation succeeds.

[DONE:6]

## Critical Constraints
- Do NOT change `showAllWindows(forOwnerPID:)` — it intentionally brings all windows forward.
- The existing `activateApplication(ownerPID:)` method should be kept as-is (only used by `showAllWindows`).
- The new method should use `activate()` or `activate(options: [])` — NOT `.activateAllWindows`.
