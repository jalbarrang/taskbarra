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
        activateApplication(ownerPID: window.ownerPID)
        raise(axWindow)
        refreshWindows()
    }

    func minimizeOrRestore(window: WindowInfo) {
        guard let axWindow = resolver.findWindow(matching: window, includeMinimized: true) else { return }

        if resolver.isMinimized(axWindow) {
            restoreIfNeeded(axWindow)
            activateApplication(ownerPID: window.ownerPID)
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
