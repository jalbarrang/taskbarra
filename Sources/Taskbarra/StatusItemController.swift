import AppKit

@MainActor
final class StatusItemController {
    private let launchAtLoginController: LaunchAtLoginControlling
    private let statusItem: NSStatusItem
    private let menu = NSMenu()
    private let launchAtLoginMenuItem = NSMenuItem()

    init(launchAtLoginController: LaunchAtLoginControlling = LaunchAtLoginController()) {
        self.launchAtLoginController = launchAtLoginController
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        configureStatusItem()
        configureMenu()
        refreshLaunchAtLoginState()
    }

    func stop() {
        NSStatusBar.system.removeStatusItem(statusItem)
    }

    private func configureStatusItem() {
        statusItem.button?.image = NSImage(
            systemSymbolName: "rectangle.bottomthird.inset.filled",
            accessibilityDescription: "Taskbarra"
        )
        statusItem.button?.imagePosition = .imageOnly
        statusItem.button?.toolTip = "Taskbarra"
        statusItem.menu = menu
    }

    private func configureMenu() {
        let aboutItem = NSMenuItem(title: "About Taskbarra", action: #selector(showAbout), keyEquivalent: "")
        aboutItem.target = self

        launchAtLoginMenuItem.title = "Launch at Login"
        launchAtLoginMenuItem.action = #selector(toggleLaunchAtLogin)
        launchAtLoginMenuItem.target = self

        let quitItem = NSMenuItem(title: "Quit Taskbarra", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self

        menu.addItem(aboutItem)
        menu.addItem(NSMenuItem.separator())
        menu.addItem(launchAtLoginMenuItem)
        menu.addItem(NSMenuItem.separator())
        menu.addItem(quitItem)
    }

    private func refreshLaunchAtLoginState() {
        launchAtLoginMenuItem.state = launchAtLoginController.isEnabled ? .on : .off
    }

    @objc private func showAbout() {
        NSApp.orderFrontStandardAboutPanel(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func toggleLaunchAtLogin() {
        do {
            try launchAtLoginController.setEnabled(!launchAtLoginController.isEnabled)
            refreshLaunchAtLoginState()
        } catch {
            refreshLaunchAtLoginState()
            presentLaunchAtLoginError(error)
        }
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }

    private func presentLaunchAtLoginError(_ error: Error) {
        let alert = NSAlert()
        alert.messageText = "Could Not Update Launch at Login"
        alert.informativeText = error.localizedDescription
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}
