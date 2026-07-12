import AppKit
import CoreGraphics
import TaskbarraCore

/// Tracks Taskbarra's intended usable desktop area on every active display.
///
/// macOS does not expose a public API that lets third-party apps mutate NSScreen.visibleFrame
/// or register a Dock-like reserved work area. The Dock uses private WindowServer/CGS behavior.
/// This type intentionally stays public-API-only: it computes per-display geometry so the
/// Accessibility coordinator can keep maximized windows out of each display's taskbar area.
@MainActor
final class WorkAreaReservation {
    private var workAreasByDisplayID: [CGDirectDisplayID: DisplayWorkArea] = [:]

    var displayIDs: Set<CGDirectDisplayID> {
        Set(workAreasByDisplayID.keys)
    }

    var workAreas: [DisplayWorkArea] {
        workAreasByDisplayID.values.sorted { $0.displayID < $1.displayID }
    }

    func apply(geometry: TaskbarGeometry, for displayID: CGDirectDisplayID) {
        let primaryScreenHeight = NSScreen.screens.first?.frame.height ?? geometry.screenFrame.height
        let converter = ScreenCoordinateConverter(primaryScreenHeight: primaryScreenHeight)
        workAreasByDisplayID[displayID] = DisplayWorkArea(
            displayID: displayID,
            screenFrame: converter.appKitToCG(geometry.screenFrame),
            usableFrame: converter.appKitToCG(geometry.usableFrameAboveTaskbar)
        )
    }

    func removeReservation(for displayID: CGDirectDisplayID) {
        workAreasByDisplayID.removeValue(forKey: displayID)
    }

    func removeAll() {
        workAreasByDisplayID.removeAll()
    }
}
