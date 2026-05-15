import AppKit
import CoreGraphics
import Foundation

struct WindowScanner {
    private let currentProcessID: pid_t

    init(currentProcessID: pid_t = ProcessInfo.processInfo.processIdentifier) {
        self.currentProcessID = currentProcessID
    }

    func scanVisibleWindows() -> [WindowInfo] {
        let options: CGWindowListOption = [
            .optionOnScreenOnly,
            .excludeDesktopElements
        ]

        guard let rawWindows = CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[String: Any]] else {
            return []
        }

        return rawWindows
            .compactMap(parseWindowInfo)
            .filter(isRelevantWindow)
            .sorted(by: windowSortOrder)
    }

    private func parseWindowInfo(_ dictionary: [String: Any]) -> WindowInfo? {
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

    private func isRelevantWindow(_ window: WindowInfo) -> Bool {
        guard window.ownerPID != currentProcessID else { return false }
        guard window.isOnScreen else { return false }
        guard window.layer == 0 else { return false }
        guard !window.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return false }
        guard window.bounds.width >= 80, window.bounds.height >= 40 else { return false }
        guard !ignoredOwnerNames.contains(window.ownerName) else { return false }

        return true
    }

    private func windowSortOrder(_ lhs: WindowInfo, _ rhs: WindowInfo) -> Bool {
        if lhs.ownerName.localizedCaseInsensitiveCompare(rhs.ownerName) != .orderedSame {
            return lhs.ownerName.localizedCaseInsensitiveCompare(rhs.ownerName) == .orderedAscending
        }

        if lhs.title.localizedCaseInsensitiveCompare(rhs.title) != .orderedSame {
            return lhs.title.localizedCaseInsensitiveCompare(rhs.title) == .orderedAscending
        }

        return lhs.id < rhs.id
    }

    private var ignoredOwnerNames: Set<String> {
        [
            "Dock",
            "Window Server",
            "SystemUIServer",
            "Notification Center",
            "Control Center",
            "Taskbarra"
        ]
    }
}
