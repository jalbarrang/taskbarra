import AppKit
import SwiftUI

@MainActor
final class AccessibilityOnboardingWindowController: NSWindowController {
    convenience init(openSystemSettings: @escaping () -> Void, quit: @escaping () -> Void) {
        let view = AccessibilityOnboardingView(openSystemSettings: openSystemSettings, quit: quit)
            .preferredColorScheme(.dark)

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 520, height: 260),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Taskbarra Setup"
        window.isReleasedWhenClosed = false
        window.center()
        window.appearance = NSAppearance(named: .darkAqua)
        window.contentView = NSHostingView(rootView: view)

        self.init(window: window)
    }

    override func showWindow(_ sender: Any?) {
        super.showWindow(sender)
        window?.makeKeyAndOrderFront(sender)
        NSApp.activate(ignoringOtherApps: true)
    }
}
