import AppKit
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var taskbarWindowController: TaskbarWindowController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        let controller = TaskbarWindowController()
        controller.showWindow(nil)
        self.taskbarWindowController = controller

        NSApp.activate(ignoringOtherApps: false)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
