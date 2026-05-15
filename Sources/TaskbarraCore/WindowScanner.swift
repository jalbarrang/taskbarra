import CoreGraphics
import Foundation

public protocol WindowInfoProviding {
    func copyWindowInfo(options: CGWindowListOption, relativeToWindow windowID: CGWindowID) -> [[String: Any]]
}

public struct CGWindowInfoProvider: WindowInfoProviding {
    public init() {}

    public func copyWindowInfo(options: CGWindowListOption, relativeToWindow windowID: CGWindowID) -> [[String: Any]] {
        CGWindowListCopyWindowInfo(options, windowID) as? [[String: Any]] ?? []
    }
}

public struct WindowScanner {
    private let currentProcessID: pid_t
    private let provider: WindowInfoProviding
    private let ignoredOwnerNames: Set<String>

    public init(
        currentProcessID: pid_t = ProcessInfo.processInfo.processIdentifier,
        provider: WindowInfoProviding = CGWindowInfoProvider(),
        ignoredOwnerNames: Set<String> = Self.defaultIgnoredOwnerNames
    ) {
        self.currentProcessID = currentProcessID
        self.provider = provider
        self.ignoredOwnerNames = ignoredOwnerNames
    }

    public func scanVisibleWindows() -> [WindowInfo] {
        let options: CGWindowListOption = [
            .optionOnScreenOnly,
            .excludeDesktopElements
        ]

        return scan(options: options)
    }

    public func scan(options: CGWindowListOption) -> [WindowInfo] {
        provider
            .copyWindowInfo(options: options, relativeToWindow: kCGNullWindowID)
            .compactMap(Self.parseWindowInfo)
            .filter(isRelevantWindow)
            .sorted(by: Self.windowSortOrder)
    }

    public static func parseWindowInfo(_ dictionary: [String: Any]) -> WindowInfo? {
        guard
            let idNumber = dictionary[kCGWindowNumber as String] as? NSNumber,
            let ownerPIDNumber = dictionary[kCGWindowOwnerPID as String] as? NSNumber,
            let ownerName = dictionary[kCGWindowOwnerName as String] as? String,
            let layerNumber = dictionary[kCGWindowLayer as String] as? NSNumber,
            let boundsDictionary = dictionary[kCGWindowBounds as String] as? NSDictionary,
            let bounds = CGRect(dictionaryRepresentation: boundsDictionary)
        else {
            return nil
        }

        let title = dictionary[kCGWindowName as String] as? String ?? ""
        let isOnScreen = (dictionary[kCGWindowIsOnscreen as String] as? NSNumber)?.boolValue ?? false

        return WindowInfo(
            id: CGWindowID(idNumber.uint32Value),
            ownerPID: ownerPIDNumber.int32Value,
            ownerName: ownerName,
            title: title,
            bounds: bounds,
            layer: layerNumber.intValue,
            isOnScreen: isOnScreen
        )
    }

    public func isRelevantWindow(_ window: WindowInfo) -> Bool {
        guard window.ownerPID != currentProcessID else { return false }
        guard window.isOnScreen else { return false }
        guard window.layer == 0 else { return false }
        guard !window.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return false }
        guard window.bounds.width >= 80, window.bounds.height >= 40 else { return false }
        guard !ignoredOwnerNames.contains(window.ownerName) else { return false }

        return true
    }

    public static func windowSortOrder(_ lhs: WindowInfo, _ rhs: WindowInfo) -> Bool {
        let ownerComparison = lhs.ownerName.localizedCaseInsensitiveCompare(rhs.ownerName)
        if ownerComparison != .orderedSame {
            return ownerComparison == .orderedAscending
        }

        let titleComparison = lhs.title.localizedCaseInsensitiveCompare(rhs.title)
        if titleComparison != .orderedSame {
            return titleComparison == .orderedAscending
        }

        return lhs.id < rhs.id
    }

    public static let defaultIgnoredOwnerNames: Set<String> = [
        "Dock",
        "Window Server",
        "SystemUIServer",
        "Notification Center",
        "Control Center",
        "Taskbarra"
    ]
}
