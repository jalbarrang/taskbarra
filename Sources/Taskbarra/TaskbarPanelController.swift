import AppKit
import CoreGraphics
import SwiftUI

@MainActor
final class TaskbarPanelController: NSWindowController {
    let displayID: CGDirectDisplayID
    private var isHiddenForFullscreen = false

    init(
        displayID: CGDirectDisplayID,
        screen: NSScreen,
        windowStore: WindowStore,
        windowDisplayStore: WindowDisplayStore,
        notificationStore: NotificationStore,
        interactionController: WindowInteractionController
    ) {
        self.displayID = displayID

        let geometry = TaskbarGeometry.forScreen(screen)
        let panel = NSPanel(
            contentRect: geometry.taskbarFrame,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        TaskbarWindowConfigurator().configure(panel)

        let rootView = TaskbarView(
            displayID: displayID,
            windowStore: windowStore,
            windowDisplayStore: windowDisplayStore,
            notificationStore: notificationStore,
            interactionController: interactionController
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .preferredColorScheme(.dark)
        panel.contentView = NSHostingView(rootView: rootView)

        super.init(window: panel)
    }

    required init?(coder: NSCoder) {
        nil
    }

    func show() {
        reposition()
        guard !isHiddenForFullscreen else { return }
        window?.orderFrontRegardless()
    }

    func reposition() {
        guard let screen = screenForDisplayID(displayID) else { return }
        window?.setFrame(TaskbarGeometry.forScreen(screen).taskbarFrame, display: true)
    }

    func setHiddenForFullscreen(_ hidden: Bool) {
        guard hidden != isHiddenForFullscreen else { return }
        isHiddenForFullscreen = hidden
        if hidden {
            window?.orderOut(nil)
        } else {
            show()
        }
    }

    func tearDown() {
        window?.orderOut(nil)
        close()
    }

    private func screenForDisplayID(_ displayID: CGDirectDisplayID) -> NSScreen? {
        NSScreen.screens.first { screen in
            guard let number = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber else {
                return false
            }
            return number.uint32Value == displayID
        }
    }
}
