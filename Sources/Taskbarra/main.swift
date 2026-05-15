import AppKit
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var appCoordinator: AppCoordinator?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        let coordinator = AppCoordinator()
        coordinator.start()
        self.appCoordinator = coordinator
    }

    func applicationWillTerminate(_ notification: Notification) {
        appCoordinator?.stop()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
