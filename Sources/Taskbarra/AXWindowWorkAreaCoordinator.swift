import ApplicationServices
import TaskbarraCore

@MainActor
final class AXWindowWorkAreaCoordinator {
    private let workAreaReservation: WorkAreaReservation
    private let policy: WindowFramePolicy
    private let resolver: AXWindowResolver
    private var lastAppliedFramesByWindowID: [WindowInfo.ID: CGRect] = [:]

    init(
        workAreaReservation: WorkAreaReservation,
        policy: WindowFramePolicy = WindowFramePolicy()
    ) {
        self.workAreaReservation = workAreaReservation
        self.policy = policy
        self.resolver = AXWindowResolver(framePolicy: policy)
    }

    func reconcile(windows: [WindowInfo]) {
        let screenFrame = workAreaReservation.screenFrame
        let usableFrame = workAreaReservation.usableFrame
        guard !screenFrame.isEmpty, !usableFrame.isEmpty else { return }

        let liveIDs = Set(windows.map(\.id))
        lastAppliedFramesByWindowID = lastAppliedFramesByWindowID.filter { liveIDs.contains($0.key) }

        for window in windows {
            let frame = window.bounds
            guard
                policy.shouldMoveMaximizedWindow(
                    windowFrame: frame,
                    screenFrame: screenFrame,
                    usableFrame: usableFrame,
                    lastAppliedFrame: lastAppliedFramesByWindowID[window.id]
                )
            else {
                continue
            }

            guard let axWindow = resolver.findWindow(matching: window) else { continue }
            guard !resolver.isTrueFullscreen(axWindow), canSetFrame(axWindow) else { continue }

            if setFrame(usableFrame, for: axWindow) {
                lastAppliedFramesByWindowID[window.id] = usableFrame
            }
        }
    }

    private func canSetFrame(_ window: AXUIElement) -> Bool {
        resolver.isAttributeSettable(kAXPositionAttribute, of: window)
            && resolver.isAttributeSettable(kAXSizeAttribute, of: window)
    }

    private func setFrame(_ frame: CGRect, for window: AXUIElement) -> Bool {
        var position = frame.origin
        var size = frame.size
        guard let positionValue = AXValueCreate(.cgPoint, &position),
            let sizeValue = AXValueCreate(.cgSize, &size)
        else { return false }

        let positionResult = AXUIElementSetAttributeValue(window, kAXPositionAttribute as CFString, positionValue)
        let sizeResult = AXUIElementSetAttributeValue(window, kAXSizeAttribute as CFString, sizeValue)
        return positionResult == .success && sizeResult == .success
    }
}
