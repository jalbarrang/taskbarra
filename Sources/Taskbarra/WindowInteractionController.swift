import AppKit
import ApplicationServices
import TaskbarraCore

@MainActor
final class WindowInteractionController {
    private let resolver: AXWindowResolver
    private let refreshWindows: () -> Void

    init(
        resolver: AXWindowResolver = AXWindowResolver(),
        refreshWindows: @escaping () -> Void = {}
    ) {
        self.resolver = resolver
        self.refreshWindows = refreshWindows
    }

    func toggle(window: WindowInfo, isActive: Bool) {
        guard let axWindow = resolver.findWindow(matching: window, includeMinimized: true) else { return }

        if isActive && !resolver.isMinimized(axWindow) {
            minimize(axWindow)
            refreshWindows()
            return
        }

        restoreIfNeeded(axWindow)
        activateApplicationForSingleWindow(ownerPID: window.ownerPID)
        raise(axWindow)
        refreshWindows()
    }

    func minimizeOrRestore(window: WindowInfo) {
        guard let axWindow = resolver.findWindow(matching: window, includeMinimized: true) else { return }

        if resolver.isMinimized(axWindow) {
            restoreIfNeeded(axWindow)
            activateApplicationForSingleWindow(ownerPID: window.ownerPID)
            raise(axWindow)
        } else {
            minimize(axWindow)
        }
        refreshWindows()
    }

    func close(window: WindowInfo) {
        guard let axWindow = resolver.findWindow(matching: window, includeMinimized: true) else { return }
        close(axWindow)
        refreshWindows()
    }

    func activate(window: WindowInfo) {
        guard let axWindow = resolver.findWindow(matching: window, includeMinimized: true) else { return }
        restoreIfNeeded(axWindow)
        activateApplicationForSingleWindow(ownerPID: window.ownerPID)
        raise(axWindow)
        refreshWindows()
    }

    func showAllWindows(forOwnerPID ownerPID: pid_t) {
        NSRunningApplication(processIdentifier: ownerPID)?.unhide()
        activateApplication(ownerPID: ownerPID)
        refreshWindows()
    }

    func hideApplication(ownerPID: pid_t) {
        NSRunningApplication(processIdentifier: ownerPID)?.hide()
        refreshWindows()
    }

    func quitApplication(ownerPID: pid_t) {
        NSRunningApplication(processIdentifier: ownerPID)?.terminate()
        refreshWindows()
    }

    func forceQuitApplication(ownerPID: pid_t) {
        NSRunningApplication(processIdentifier: ownerPID)?.forceTerminate()
        refreshWindows()
    }

    func relaunchApplication(ownerPID: pid_t) {
        guard let application = NSRunningApplication(processIdentifier: ownerPID) else { return }
        let launchURL = application.bundleURL ?? application.executableURL
        application.terminate()
        guard let launchURL else { return }
        NSWorkspace.shared.openApplication(at: launchURL, configuration: NSWorkspace.OpenConfiguration())
    }

    func openApplicationInFinder(ownerPID: pid_t) {
        guard let bundleURL = NSRunningApplication(processIdentifier: ownerPID)?.bundleURL else { return }
        NSWorkspace.shared.activateFileViewerSelecting([bundleURL])
    }

    func copyBundleIdentifier(ownerPID: pid_t) {
        guard let bundleIdentifier = NSRunningApplication(processIdentifier: ownerPID)?.bundleIdentifier else { return }
        copyToPasteboard(bundleIdentifier)
    }

    func copyProcessIdentifier(ownerPID: pid_t) {
        copyToPasteboard(String(ownerPID))
    }

    func supportsRelaunch(ownerPID: pid_t) -> Bool {
        guard let application = NSRunningApplication(processIdentifier: ownerPID) else { return false }
        return application.bundleURL != nil || application.executableURL != nil
    }

    func supportsOpenInFinder(ownerPID: pid_t) -> Bool {
        NSRunningApplication(processIdentifier: ownerPID)?.bundleURL != nil
    }

    func supportsCopyBundleIdentifier(ownerPID: pid_t) -> Bool {
        NSRunningApplication(processIdentifier: ownerPID)?.bundleIdentifier != nil
    }

    private func minimize(_ window: AXUIElement) {
        setMinimized(true, for: window)
    }

    private func restoreIfNeeded(_ window: AXUIElement) {
        guard resolver.isMinimized(window) else { return }
        setMinimized(false, for: window)
    }

    private func setMinimized(_ minimized: Bool, for window: AXUIElement) {
        let value = NSNumber(value: minimized)
        AXUIElementSetAttributeValue(window, kAXMinimizedAttribute as CFString, value)
    }

    private func activateApplication(ownerPID: pid_t) {
        NSRunningApplication(processIdentifier: ownerPID)?.activate(options: [.activateAllWindows])
    }

    private func activateApplicationForSingleWindow(ownerPID: pid_t) {
        NSRunningApplication(processIdentifier: ownerPID)?.activate()
    }

    private func copyToPasteboard(_ value: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(value, forType: .string)
    }

    private func raise(_ window: AXUIElement) {
        AXUIElementPerformAction(window, kAXRaiseAction as CFString)
    }

    private func close(_ window: AXUIElement) {
        var closeButton: CFTypeRef?
        let error = AXUIElementCopyAttributeValue(window, kAXCloseButtonAttribute as CFString, &closeButton)
        guard error == .success, let closeButton else { return }
        AXUIElementPerformAction(unsafeDowncast(closeButton, to: AXUIElement.self), kAXPressAction as CFString)
    }
}
