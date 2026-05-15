import AppKit

@MainActor
final class ApplicationIconProvider {
    private var cache: [String: NSImage] = [:]

    func icon(forOwnerPID ownerPID: pid_t) -> NSImage? {
        guard let application = NSRunningApplication(processIdentifier: ownerPID) else {
            return nil
        }

        let cacheKey = application.bundleIdentifier ?? "pid:\(ownerPID)"
        if let cachedIcon = cache[cacheKey] {
            return cachedIcon
        }

        guard let icon = application.icon else {
            return nil
        }

        icon.size = NSSize(width: 24, height: 24)
        cache[cacheKey] = icon
        return icon
    }
}
