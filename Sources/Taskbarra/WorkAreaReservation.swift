import AppKit

/// Tracks the intended usable desktop area above Taskbarra.
///
/// macOS does not expose a public API that lets third-party apps mutate NSScreen.visibleFrame
/// or register a Dock-like reserved work area. The Dock uses private WindowServer/CGS behavior.
/// This type intentionally stays public-API-only: it computes the reserved geometry so later
/// Accessibility-based window management can keep maximized windows out of the bar area.
@MainActor
final class WorkAreaReservation {
    private(set) var screenFrame: NSRect = .zero
    private(set) var reservedTaskbarFrame: NSRect = .zero
    private(set) var usableFrame: NSRect = .zero

    /// Usable frame expressed in the Accessibility/CoreGraphics window coordinate space.
    ///
    /// Taskbarra's panel is positioned with AppKit coordinates (origin at the bottom-left of
    /// the main display), but `CGWindowListCopyWindowInfo` and Accessibility window positions
    /// use a top-left origin. Reserving a bottom bar therefore means reducing the height while
    /// keeping the window's top y unchanged in AX/CG coordinates.
    var usableFrameInWindowCoordinates: NSRect {
        convertToWindowCoordinates(usableFrame)
    }

    func apply(geometry: TaskbarGeometry) {
        screenFrame = geometry.screenFrame
        reservedTaskbarFrame = geometry.taskbarFrame
        usableFrame = geometry.usableFrameAboveTaskbar
    }

    private func convertToWindowCoordinates(_ frame: NSRect) -> NSRect {
        guard !screenFrame.isEmpty, !frame.isEmpty else { return frame }
        return NSRect(
            x: frame.minX,
            y: screenFrame.minY + (screenFrame.maxY - frame.maxY),
            width: frame.width,
            height: frame.height
        )
    }
}
