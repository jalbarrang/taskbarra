import AppKit
import ApplicationServices
import TaskbarraCore

@MainActor
protocol PassiveAXWindowScanning {
    func scanMinimizedWindows() -> [PassiveAXWindowSnapshot]
}

@MainActor
struct PassiveAXWindowScanner: PassiveAXWindowScanning {
    private let resolver: AXWindowResolver

    init(resolver: AXWindowResolver = AXWindowResolver()) {
        self.resolver = resolver
    }

    func scanMinimizedWindows() -> [PassiveAXWindowSnapshot] {
        NSWorkspace.shared.runningApplications
            .filter { !$0.isTerminated && $0.activationPolicy == .regular }
            .flatMap(scanMinimizedWindows)
    }

    private func scanMinimizedWindows(for application: NSRunningApplication) -> [PassiveAXWindowSnapshot] {
        let appElement = AXUIElementCreateApplication(application.processIdentifier)
        guard let windows = resolver.copyWindows(for: appElement) else { return [] }

        return windows.compactMap { window in
            guard resolver.isMinimized(window) else { return nil }
            let frame = resolver.frame(of: window) ?? .zero
            let title = resolver.stringAttribute(kAXTitleAttribute, of: window) ?? ""
            return PassiveAXWindowSnapshot(
                ownerPID: application.processIdentifier,
                ownerName: application.localizedName ?? application.bundleIdentifier ?? "Unknown",
                title: title,
                frame: frame,
                isMinimized: true
            )
        }
    }
}
