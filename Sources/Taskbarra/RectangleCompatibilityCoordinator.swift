import AppKit

@MainActor
final class RectangleCompatibilityCoordinator {
    private let bundleIdentifier = "com.knollsoft.Rectangle"
    private let bottomGapKey = "screenEdgeGapBottom"

    func reserveTaskbarSpaceIfRectangleIsPresent(taskbarHeight: CGFloat) {
        guard isRectanglePresent else { return }
        guard let defaults = UserDefaults(suiteName: bundleIdentifier) else { return }

        let existingGap = defaults.float(forKey: bottomGapKey)
        let reservedGap = Float(taskbarHeight.rounded(.up))
        guard existingGap < reservedGap else { return }

        defaults.set(reservedGap, forKey: bottomGapKey)
        defaults.synchronize()
    }

    private var isRectanglePresent: Bool {
        NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleIdentifier) != nil
            || NSWorkspace.shared.runningApplications.contains { $0.bundleIdentifier == bundleIdentifier }
    }
}
