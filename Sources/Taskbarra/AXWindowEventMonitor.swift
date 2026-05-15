import AppKit
import ApplicationServices

@MainActor
final class AXWindowEventMonitor {
    private let onWindowEvent: () -> Void
    private var appObservers: [pid_t: AXObserver] = [:]
    private var workspaceObservers: [NSObjectProtocol] = []

    init(onWindowEvent: @escaping () -> Void) {
        self.onWindowEvent = onWindowEvent
    }

    func start() {
        observeWorkspaceEvents()
        refreshObservedApplications()
        onWindowEvent()
    }

    func stop() {
        for observer in workspaceObservers {
            NSWorkspace.shared.notificationCenter.removeObserver(observer)
        }
        workspaceObservers.removeAll()

        for observer in appObservers.values {
            let runLoopSource = AXObserverGetRunLoopSource(observer)
            CFRunLoopRemoveSource(CFRunLoopGetMain(), runLoopSource, .defaultMode)
        }
        appObservers.removeAll()
    }

    private func observeWorkspaceEvents() {
        guard workspaceObservers.isEmpty else { return }

        let notifications: [NSNotification.Name] = [
            NSWorkspace.didLaunchApplicationNotification,
            NSWorkspace.didTerminateApplicationNotification,
            NSWorkspace.didActivateApplicationNotification,
            NSWorkspace.activeSpaceDidChangeNotification,
        ]

        workspaceObservers = notifications.map { name in
            NSWorkspace.shared.notificationCenter.addObserver(
                forName: name,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                Task { @MainActor in
                    self?.refreshObservedApplications()
                    self?.onWindowEvent()
                }
            }
        }
    }

    private func refreshObservedApplications() {
        let runningPIDs = Set(
            NSWorkspace.shared.runningApplications
                .filter { !$0.isTerminated && $0.activationPolicy == .regular }
                .map(\.processIdentifier)
        )

        for pid in Set(appObservers.keys).subtracting(runningPIDs) {
            removeObserver(for: pid)
        }

        for pid in runningPIDs where appObservers[pid] == nil {
            addObserver(for: pid)
        }
    }

    private func addObserver(for pid: pid_t) {
        var observer: AXObserver?
        let createError = AXObserverCreate(pid, Self.axObserverCallback, &observer)
        guard createError == .success, let observer else { return }

        let appElement = AXUIElementCreateApplication(pid)
        let refcon = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())

        for notification in Self.applicationNotifications {
            AXObserverAddNotification(observer, appElement, notification as CFString, refcon)
        }

        if let windows = copyWindows(for: appElement) {
            for window in windows {
                for notification in Self.windowNotifications {
                    AXObserverAddNotification(observer, window, notification as CFString, refcon)
                }
            }
        }

        let runLoopSource = AXObserverGetRunLoopSource(observer)
        CFRunLoopAddSource(CFRunLoopGetMain(), runLoopSource, .defaultMode)

        appObservers[pid] = observer
    }

    private func removeObserver(for pid: pid_t) {
        guard let observer = appObservers.removeValue(forKey: pid) else { return }
        let runLoopSource = AXObserverGetRunLoopSource(observer)
        CFRunLoopRemoveSource(CFRunLoopGetMain(), runLoopSource, .defaultMode)
    }

    private func handleNotification() {
        onWindowEvent()
    }

    private func copyWindows(for appElement: AXUIElement) -> [AXUIElement]? {
        var value: CFTypeRef?
        let error = AXUIElementCopyAttributeValue(appElement, kAXWindowsAttribute as CFString, &value)
        guard error == .success else { return nil }
        return value as? [AXUIElement]
    }

    private static let applicationNotifications: [String] = [
        kAXWindowCreatedNotification as String,
        kAXFocusedWindowChangedNotification as String,
    ]

    private static let windowNotifications: [String] = [
        kAXTitleChangedNotification as String,
        kAXUIElementDestroyedNotification as String,
        kAXWindowMiniaturizedNotification as String,
        kAXWindowDeminiaturizedNotification as String,
        kAXWindowMovedNotification as String,
        kAXWindowResizedNotification as String,
    ]

    private static let axObserverCallback: AXObserverCallback = { _, _, _, refcon in
        guard let refcon else { return }
        let monitor = Unmanaged<AXWindowEventMonitor>.fromOpaque(refcon).takeUnretainedValue()
        Task { @MainActor in
            monitor.handleNotification()
        }
    }
}
