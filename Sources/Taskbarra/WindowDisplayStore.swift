import CoreGraphics
import Observation
import TaskbarraCore

@Observable
@MainActor
final class WindowDisplayStore {
    private let screenAssigner: WindowScreenAssigner
    private(set) var windowIDsByDisplay: [CGDirectDisplayID: [WindowInfo.ID]] = [:]

    init(screenAssigner: WindowScreenAssigner = WindowScreenAssigner()) {
        self.screenAssigner = screenAssigner
    }

    func update(
        windows: [WindowInfo],
        displays: [DisplayDescriptor],
        fallbackDisplayID: CGDirectDisplayID?
    ) {
        let assignments = screenAssigner.assignments(
            for: windows,
            among: displays,
            fallbackDisplayID: fallbackDisplayID
        )
        var groupedIDs = Dictionary(
            uniqueKeysWithValues: displays.map { ($0.id, [WindowInfo.ID]()) }
        )
        for window in windows {
            guard let displayID = assignments[window.id], groupedIDs[displayID] != nil else { continue }
            groupedIDs[displayID, default: []].append(window.id)
        }
        windowIDsByDisplay = groupedIDs
    }

    func windows(for displayID: CGDirectDisplayID, from windows: [WindowInfo]) -> [WindowInfo] {
        let visibleIDs = Set(windowIDsByDisplay[displayID] ?? [])
        return windows.filter { visibleIDs.contains($0.id) }
    }

    func removeDisplay(_ displayID: CGDirectDisplayID) {
        windowIDsByDisplay.removeValue(forKey: displayID)
    }

    func removeAll() {
        windowIDsByDisplay.removeAll()
    }
}
