import ApplicationServices
import TaskbarraCore

@MainActor
struct WindowTitleResolver {
    private let resolver: AXWindowResolver

    init(resolver: AXWindowResolver = AXWindowResolver()) {
        self.resolver = resolver
    }

    func bestEffortTitle(for window: WindowInfo) -> String {
        if !window.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return window.title
        }

        guard let axWindow = resolver.findWindow(matching: window, includeMinimized: true) else {
            return window.ownerName
        }

        let axTitle = resolver.stringAttribute(kAXTitleAttribute, of: axWindow) ?? ""
        if !axTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return axTitle
        }

        return window.ownerName
    }
}
