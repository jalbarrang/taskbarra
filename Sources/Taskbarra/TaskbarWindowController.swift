import AppKit
import SwiftUI

final class TaskbarWindowController: NSWindowController {
    private let barHeight: CGFloat = 48
    private let windowStore: WindowStore

    convenience init() {
        let windowStore = WindowStore()
        let screen = NSScreen.main ?? NSScreen.screens.first
        let frame = Self.windowFrame(for: screen, height: 48)

        let panel = NSPanel(
            contentRect: frame,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        panel.title = "Taskbarra"
        panel.isReleasedWhenClosed = false
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        panel.hidesOnDeactivate = false
        panel.isMovable = false
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = true
        panel.appearance = NSAppearance(named: .darkAqua)

        let rootView = TaskbarView(windowStore: windowStore)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .preferredColorScheme(.dark)

        panel.contentView = NSHostingView(rootView: rootView)

        self.init(window: panel, windowStore: windowStore)

        windowStore.startPolling()
    }

    init(window: NSWindow?, windowStore: WindowStore) {
        self.windowStore = windowStore
        super.init(window: window)
    }

    required init?(coder: NSCoder) {
        self.windowStore = WindowStore()
        super.init(coder: coder)
    }

    override func showWindow(_ sender: Any?) {
        reposition()
        super.showWindow(sender)
        window?.orderFrontRegardless()
    }

    func reposition() {
        guard let window else { return }
        let screen = NSScreen.main ?? NSScreen.screens.first
        window.setFrame(Self.windowFrame(for: screen, height: barHeight), display: true)
    }

    private static func windowFrame(for screen: NSScreen?, height: CGFloat) -> NSRect {
        guard let screen else {
            return NSRect(x: 0, y: 0, width: 800, height: height)
        }

        return NSRect(
            x: screen.frame.minX,
            y: screen.frame.minY,
            width: screen.frame.width,
            height: height
        )
    }
}
