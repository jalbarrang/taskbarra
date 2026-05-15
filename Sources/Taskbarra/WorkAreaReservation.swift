import AppKit

/// Tracks the intended usable desktop area above Taskbarra.
///
/// macOS does not expose a public API that lets third-party apps mutate NSScreen.visibleFrame
/// or register a Dock-like reserved work area. The Dock uses private WindowServer/CGS behavior.
/// This type intentionally stays public-API-only: it computes the reserved geometry so later
/// Accessibility-based window management can keep maximized windows out of the bar area.
@MainActor
final class WorkAreaReservation {
    private(set) var reservedTaskbarFrame: NSRect = .zero
    private(set) var usableFrame: NSRect = .zero

    func apply(geometry: TaskbarGeometry) {
        reservedTaskbarFrame = geometry.taskbarFrame
        usableFrame = geometry.usableFrameAboveTaskbar
    }
}
