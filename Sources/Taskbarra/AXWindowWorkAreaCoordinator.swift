import ApplicationServices
import TaskbarraCore

@MainActor
final class AXWindowWorkAreaCoordinator {
    private let workAreaReservation: WorkAreaReservation
    private let policy: WindowFramePolicy
    private let resolver: AXWindowResolver
    private let windowWorkAreaResolver: WindowWorkAreaResolver
    private var lastAppliedFramesByWindowID: [WindowInfo.ID: CGRect] = [:]

    init(
        workAreaReservation: WorkAreaReservation,
        policy: WindowFramePolicy = WindowFramePolicy()
    ) {
        self.workAreaReservation = workAreaReservation
        self.policy = policy
        self.resolver = AXWindowResolver(framePolicy: policy)
        self.windowWorkAreaResolver = WindowWorkAreaResolver()
    }

    func reconcile(windows: [WindowInfo]) {
        let workAreas = workAreaReservation.workAreas
        guard !workAreas.isEmpty else { return }

        let liveIDs = Set(windows.map(\.id))
        lastAppliedFramesByWindowID = lastAppliedFramesByWindowID.filter { liveIDs.contains($0.key) }

        for window in windows {
            guard let workArea = windowWorkAreaResolver.workArea(for: window, among: workAreas) else { continue }
            guard let axWindow = resolver.findWindow(matching: window) else { continue }
            guard !resolver.isTrueFullscreen(axWindow), canSetFrame(axWindow) else { continue }

            let frame = resolver.frame(of: axWindow) ?? window.bounds
            guard
                policy.shouldMoveMaximizedWindow(
                    windowFrame: frame,
                    screenFrame: workArea.screenFrame,
                    usableFrame: workArea.usableFrame,
                    lastAppliedFrame: lastAppliedFramesByWindowID[window.id]
                )
            else {
                continue
            }

            if setFrame(workArea.usableFrame, for: axWindow) {
                lastAppliedFramesByWindowID[window.id] = workArea.usableFrame
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

        let initialSizeResult = AXUIElementSetAttributeValue(window, kAXSizeAttribute as CFString, sizeValue)
        let positionResult = AXUIElementSetAttributeValue(window, kAXPositionAttribute as CFString, positionValue)
        let finalSizeResult = AXUIElementSetAttributeValue(window, kAXSizeAttribute as CFString, sizeValue)
        return initialSizeResult == .success && positionResult == .success && finalSizeResult == .success
    }
}
