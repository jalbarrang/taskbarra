# Single Window Activate on Click

When clicking a window button in the taskbar, only bring that specific window to the front instead of all windows belonging to the same application.

## Context

- **Root cause**: `WindowInteractionController.activateApplication(ownerPID:)` uses `.activateAllWindows` option, which raises every window of the app.
- This method is called by `toggle(window:isActive:)`, `activate(window:)`, `minimizeOrRestore(window:)`, and `showAllWindows(forOwnerPID:)`.
- `showAllWindows` should keep `.activateAllWindows` — it's the explicit "show all" action.
- The `raise(axWindow)` call (AXRaiseAction) already targets the specific window, but `.activateAllWindows` undoes the single-window intent by bringing siblings forward too.

## Plan:

1. **In `Sources/Taskbarra/WindowInteractionController.swift`** — Split `activateApplication` into two variants:
   - Rename the current `activateApplication(ownerPID:)` (with `.activateAllWindows`) to `activateApplicationShowingAllWindows(ownerPID:)` (or keep as-is but only used by `showAllWindows`).
   - Add a new private method `activateApplicationOnly(ownerPID:)` that calls `.activate(options: [])` (empty options — activates the app without raising all its windows).

2. **Update callers**:
   - `toggle(window:isActive:)` — change to use `activateApplicationOnly(ownerPID:)`
   - `activate(window:)` — change to use `activateApplicationOnly(ownerPID:)`
   - `minimizeOrRestore(window:)` — change to use `activateApplicationOnly(ownerPID:)`
   - `showAllWindows(forOwnerPID:)` — keep using `activateApplication(ownerPID:)` with `.activateAllWindows`

3. **Verify** the raise(axWindow) call after activation still correctly brings the single window to the front when the app is activated without `.activateAllWindows`.

## Risks / Open Questions

- **macOS behavior**: With `activate(options: [])`, the app becomes frontmost but doesn't automatically order all its windows above other apps' windows. The subsequent `AXRaiseAction` should bring the clicked window to the front. Other windows of the same app may remain behind other apps' windows — this is the desired behavior.
- If a window is on a different Space, `activate(options: [])` might not switch to that Space. Current behavior may already have this limitation. Not a regression.
