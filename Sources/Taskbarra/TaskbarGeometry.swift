import AppKit

struct TaskbarGeometry {
    static let defaultHeight: CGFloat = 48

    let screenFrame: NSRect
    let barHeight: CGFloat

    var taskbarFrame: NSRect {
        NSRect(
            x: screenFrame.minX,
            y: screenFrame.minY,
            width: screenFrame.width,
            height: barHeight
        )
    }

    var usableFrameAboveTaskbar: NSRect {
        NSRect(
            x: screenFrame.minX,
            y: screenFrame.minY + barHeight,
            width: screenFrame.width,
            height: max(0, screenFrame.height - barHeight)
        )
    }

    static func forMainScreen(barHeight: CGFloat = Self.defaultHeight) -> TaskbarGeometry {
        TaskbarGeometry(
            screenFrame: (NSScreen.main ?? NSScreen.screens.first)?.frame
                ?? NSRect(x: 0, y: 0, width: 800, height: 600),
            barHeight: barHeight
        )
    }
}
